plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val googleServicesFile = file("google-services.json")
val googleServicesMatchesApp =
    googleServicesFile.exists() &&
        googleServicesFile.readText().contains("\"package_name\": \"com.vyparhub.mobile\"")

val releaseBuildRequested = gradle.startParameter.taskNames.any {
    it.contains("release", ignoreCase = true)
}

fun requiredReleaseSigningValue(name: String): String =
    System.getenv(name)?.takeIf { it.isNotBlank() }
        ?: throw GradleException("$name must be set for release signing.")

if (googleServicesMatchesApp) {
    apply(plugin = "com.google.gms.google-services")
}

android {
    namespace = "com.vyparhub.mobile"
    compileSdk = 36
    ndkVersion = "28.2.13676358"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.vyparhub.mobile"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (releaseBuildRequested) {
                storeFile = file(requiredReleaseSigningValue("ANDROID_KEYSTORE_PATH"))
                storePassword = requiredReleaseSigningValue("ANDROID_KEYSTORE_PASSWORD")
                keyAlias = requiredReleaseSigningValue("ANDROID_KEY_ALIAS")
                keyPassword = requiredReleaseSigningValue("ANDROID_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
