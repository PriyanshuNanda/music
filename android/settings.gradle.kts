pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
        flutterSdkPath
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        gradlePluginPortal()
        google()
        mavenCentral()
        
        maven("https://chaquo.com/maven")
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.7.0" apply false
    id("org.jetbrains.kotlin.android") version "1.8.22" apply false
}

dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
        maven {
            url = uri("https://chaquo.com/maven")
        }
    }
}

gradle.beforeProject {
    System.setProperty("org.gradle.java.installations.auto-detect", "true")
    System.setProperty("org.gradle.java.installations.auto-download", "true")
    System.setProperty("org.gradle.java.installations.fromEnv", "true")
}

include(":app")
