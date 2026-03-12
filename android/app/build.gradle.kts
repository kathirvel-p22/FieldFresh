plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.fieldfresh.app"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    // Build features configuration
    buildFeatures {
        buildConfig = false  // Disable BuildConfig to avoid compatibility issues
    }

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
        
        // Suppress Kotlin warnings
        freeCompilerArgs += listOf(
            "-Xsuppress-version-warnings",
            "-Xlint:-options"
        )
    }

    defaultConfig {
        applicationId = "com.fieldfresh.app"
        minSdk = flutter.minSdkVersion
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
        
        // Suppress lint warnings
        lint {
            disable += setOf("ObsoleteJavaVersion", "GradleDeprecated")
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false  // Disable minification to avoid R8 issues
            isShrinkResources = false  // Disable resource shrinking
            // proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
        debug {
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
    
    // Suppress lint warnings
    lint {
        disable += setOf("ObsoleteJavaVersion", "GradleDeprecated", "NewerVersionAvailable")
        abortOnError = false
        checkReleaseBuilds = false
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation(platform("com.google.firebase:firebase-bom:32.7.0"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-messaging")
    
    // Google Play Core for Flutter deferred components
    implementation("com.google.android.play:core:1.10.3")
    implementation("com.google.android.play:core-ktx:1.8.1")
}
