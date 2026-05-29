#!/bin/bash
#
# Regenerates the OkHttp Swift wrappers for every supported OkHttp major version.
#
# This script is the single source of truth for the generated sources under
# Sources/OkHttp/v4 and Sources/OkHttp/v5. You can delete those directories
# entirely, run this script, and the project will compile again — no manual
# edits required. All post-processing (duplicate-method removal, stripping of
# synthetic accessors, trait #if guards, per-version file naming) is applied
# here.
#
# Selection of which version compiles is done with the SwiftPM `OkHttp4` trait
# (see Package.swift): the default build uses OkHttp 5; enabling `OkHttp4` uses
# OkHttp 4. Each version's files are therefore guarded accordingly.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

SWIFT_JAVA="$ROOT/.build/checkouts/swift-java"
DEPENDS=(
    --depends-on "SwiftJava=$SWIFT_JAVA/Sources/SwiftJava/swift-java.config"
    --depends-on "JavaUtil=$SWIFT_JAVA/Sources/JavaStdlib/JavaUtil/swift-java.config"
)

# generate <version-tag> <config-path> <trait-guard>
#   version-tag  e.g. v4   -> output dir Sources/OkHttp/v4, files named *.v4.swift
#   config-path  the version-specific swift-java config (pins the OkHttp version)
#   trait-guard  the #if condition under which this version compiles
generate() {
    local version="$1"
    local config="$2"
    local guard="$3"
    local outdir="$ROOT/Sources/OkHttp/$version"
    local tmp
    tmp="$(mktemp -d)"

    echo "==> [$version] Resolving classpath from $config ..."
    # Writes Sources/OkHttp/OkHttp.swift-java.classpath (gitignored), which
    # wrap-java then auto-discovers for this module.
    swift run swift-java resolve \
        --config "$config" \
        --swift-module OkHttp \
        --output-directory "$ROOT/Sources/OkHttp"

    echo "==> [$version] Generating Swift wrappers ..."
    swift run swift-java wrap-java \
        --swift-module OkHttp \
        --config "$config" \
        "${DEPENDS[@]}" \
        -o "$tmp"

    echo "==> [$version] Post-processing generated sources ..."

    # Remove the duplicate close() inherited from java.nio.channels.Channel in
    # BufferedSource. okio.Source.close() is kept; the Channel variant is an
    # invalid redeclaration that otherwise fails to compile.
    if [[ -f "$tmp/BufferedSource.swift" ]]; then
        perl -i -0pe 's/  \/\/\/ Java method `close`\.\n  \/\/\/\n  \/\/\/ ### Java method signature\n  \/\/\/ ```java\n  \/\/\/ public abstract void java\.nio\.channels\.Channel\.close\(\) throws java\.io\.IOException\n  \/\/\/ ```\n\@JavaMethod\n  public func close\(\) throws\n\n//' \
            "$tmp/BufferedSource.swift"
    fi

    # Strip the synthetic Kotlin companion accessors access$getDEFAULT_*$cp.
    # They are internal (not real API) and wrap to a raw `java.util.List`, which
    # generates as the generic Swift `List` with no type arguments and fails to
    # compile. The config's filterExclude catches these on OkHttp 4 but not on
    # OkHttp 5 (newer Kotlin); removing them here is version-agnostic.
    if [[ -f "$tmp/OkHttpClient.swift" ]]; then
        perl -i -0pe 's/ *\/\/\/ Java method `access\$getDEFAULT_CONNECTION_SPECS\$cp`\..*?public func access\$getDEFAULT_CONNECTION_SPECS\$cp\(\) -> List!\n//s' \
            "$tmp/OkHttpClient.swift"
        perl -i -0pe 's/ *\/\/\/ Java method `access\$getDEFAULT_PROTOCOLS\$cp`\..*?public func access\$getDEFAULT_PROTOCOLS\$cp\(\) -> List!\n//s' \
            "$tmp/OkHttpClient.swift"
    fi

    echo "==> [$version] Installing into $outdir under guard '$guard' ..."
    rm -rf "$outdir"
    mkdir -p "$outdir"
    for f in "$tmp"/*.swift; do
        local base
        base="$(basename "$f" .swift)"
        # Wrap each file in its trait guard so exactly one version's wrappers
        # compile. Files are suffixed with the version tag so basenames are
        # unique within the single OkHttp target (SwiftPM names object files by
        # basename and rejects collisions).
        {
            echo "$guard"
            cat "$f"
            echo "#endif"
        } >"$outdir/$base.$version.swift"
    done

    rm -rf "$tmp"
    echo "==> [$version] Done ($(ls "$outdir"/*.swift | wc -l | tr -d ' ') files)."
}

generate v4 "$ROOT/Sources/OkHttp/swift-java.v4.config" "#if OkHttp4"
generate v5 "$ROOT/Sources/OkHttp/swift-java.v5.config" "#if !OkHttp4"

echo "All wrappers generated. Build with 'swift build' (OkHttp 5) or 'swift build --traits OkHttp4'."
