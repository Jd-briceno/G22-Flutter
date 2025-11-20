plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

repositories {
    google()
    mavenCentral()
    maven { url = uri("https://jitpack.io") }
}

android {
    namespace = "com.example.melodymuse"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.melodymuse"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        manifestPlaceholders["redirectSchemeName"] = "melodymuse"
        manifestPlaceholders["redirectHostName"] = "callback"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:34.3.0"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-auth")

    // ✅ Spotify App Remote SDK desde JitPack
    implementation("com.github.spotify:android-app-remote-sdk:0.8.0-appremote_v2.1.0-auth")

    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
