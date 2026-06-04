import java.io.File

plugins {
    application
}

// Define properties for the Swift build
val swiftProjectDir = file("src/main/swift")
val swiftLibraryName = "SampleLib"

// Custom task to build the Swift part of the project. SwiftPM selects the host
// triple automatically, so this builds correctly on both macOS and Linux.
val buildSwift = tasks.register<Exec>("buildSwift") {
    group = "build"
    description = "Builds the Swift library and generates Java bindings."
    workingDir(swiftProjectDir)
    commandLine("swift", "build")
}

// Ask SwiftPM where it puts build products on this host rather than hardcoding
// a triple. This directory holds the compiled dynamic library
// (libSampleLib.dylib on macOS, libSampleLib.so on Linux) — i.e. what
// System.loadLibrary needs on java.library.path.
val swiftBinPath: Provider<String> = providers.exec {
    workingDir(swiftProjectDir)
    commandLine("swift", "build", "--show-bin-path")
}.standardOutput.asText.map { it.trim() }

// Path to the directory where the swift-java plugin generates .java files, as you provided.
val swiftGeneratedJavaSourcesDir = swiftProjectDir.resolve(".build/plugins/outputs/swift/$swiftLibraryName/destination/JExtractSwiftPlugin/src/generated")

// Add the generated sources to the main Java source set
sourceSets.main {
    java {
        srcDir(swiftGeneratedJavaSourcesDir)
    }
}

repositories {
    mavenLocal()
    mavenCentral()
}

dependencies {
    // The generated sources are now part of the compilation, so no explicit file dependency is needed.

    // OkHttp must be on the classpath at runtime, since the Swift wrappers call
    // into it over JNI.
    implementation(libs.okhttp)

    implementation("org.swift.swiftkit:swiftkit-core:1.0-SNAPSHOT")

    testRuntimeOnly("org.junit.platform:junit-platform-launcher")
}

// Apply a specific Java toolchain to ease working on different environments.
java {
    toolchain {
        languageVersion = JavaLanguageVersion.of(21)
    }
}

application {
    // Define the main class for the application.
    mainClass = "org.example.App"
}

// Ensure the Swift code is built before the Java code is compiled
tasks.named("compileJava").configure {
    dependsOn(buildSwift)
}

// Point java.library.path at the SwiftPM output directory (resolved per host)
// so System.loadLibrary can find the compiled Swift library when the app runs.
tasks.named<JavaExec>("run") {
    dependsOn(buildSwift)
    val binPath = swiftBinPath
    doFirst {
        systemProperty("java.library.path", binPath.get())
    }
}

tasks.named<Test>("test") {
    // Use JUnit Platform for unit tests.
    useJUnitPlatform()
}
