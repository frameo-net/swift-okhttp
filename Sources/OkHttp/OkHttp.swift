// Hand-written, always-present source for the `OkHttp` module.
//
// The actual API is the set of generated Java-to-Swift wrappers under `v4/` and
// `v5/`, selected at build time by the `OkHttp4` package trait (see
// Package.swift): the default build targets OkHttp 5; enabling `OkHttp4`
// targets OkHttp 4. Every file in `v4/` is guarded by `#if OkHttp4` and every
// file in `v5/` by `#if !OkHttp4`, so exactly one set ever compiles.
//
// This file exists so the `OkHttp` target always has at least one source,
// including immediately after deleting the generated wrappers to regenerate
// them with `scripts/generate-wrappers.sh`. Without it, SwiftPM would reject
// the manifest ("target 'OkHttp' is empty") and the generator — which itself
// runs `swift run swift-java` — could not start.
//
// When additional OkHttp majors are added, this is the place to put a
// `#error` guard rejecting mutually exclusive version-trait combinations.
