import java.io.File

plugins {
    application
}

// Define properties for the Swift build
val swiftProjectDir = file("src/main/swift")
val swiftArch = "arm64-apple-macosx"
val swiftBuildDir = swiftProjectDir.resolve(".build/${swiftArch}/debug")
val swiftLibraryName = "SampleLib"

// Custom task to build the Swift part of the project
val buildSwift = tasks.register<Exec>("buildSwift") {
    group = "build"
    description = "Builds the Swift library and generates Java bindings."
    workingDir(swiftProjectDir)
    // Using --triple ensures a consistent build architecture and output path
    commandLine("swift", "build")
}

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

    // Set the java.library.path to where the compiled .dylib file is located
    // This allows System.loadLibrary to find your Swift code.
    applicationDefaultJvmArgs = listOf("-Djava.library.path=${swiftBuildDir}")
}

// Ensure the Swift code is built before the Java code is compiled
tasks.named("compileJava").configure {
    dependsOn(buildSwift)
}

tasks.named<Test>("test") {
    // Use JUnit Platform for unit tests.
    useJUnitPlatform()
}
