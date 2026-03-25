#!/bin/bash

set -euo pipefail

echo "Resolving class path..."

swift run swift-java resolve Sources/OkHttp/swift-java.config --swift-module OkHttp --output-directory Sources/OkHttp

echo "Generating Swift Wrappers..."

swift run swift-java wrap-java \
    --swift-module OkHttp \
    --config Sources/OkHttp/swift-java.config \
    --depends-on SwiftJava=.build/checkouts/swift-java/Sources/SwiftJava/swift-java.config \
    --depends-on JavaUtil=.build/checkouts/swift-java/Sources/JavaStdlib/JavaUtil/swift-java.config

echo "Removing duplicate close"

# Remove duplicate close() inherited from java.nio.channels.Channel in BufferedSource.
# okio.Source.close() is kept; the Channel variant causes a compile error due to duplication.
perl -i -0pe 's/  \/\/\/ Java method `close`\.\n  \/\/\/\n  \/\/\/ ### Java method signature\n  \/\/\/ ```java\n  \/\/\/ public abstract void java\.nio\.channels\.Channel\.close\(\) throws java\.io\.IOException\n  \/\/\/ ```\n\@JavaMethod\n  public func close\(\) throws\n\n//' \
    Sources/OkHttp/BufferedSource.swift