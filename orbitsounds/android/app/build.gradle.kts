plugins {
    id("com.android.application")
    id("kotlin-android")
    // El plugin de Flutter
    id("dev.flutter.flutter-gradle-plugin")
    // 🔹 IMPORTANTE: Plugin de Google Services
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.melodymuse"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.melodymuse"
        minSdk = 24   // Firebase Auth requiere minSdk 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
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
    // 🔹 BOM de Firebase (maneja versiones compatibles)
    implementation(platform("com.google.firebase:firebase-bom:34.3.0"))

    // 🔹 Firebase básico
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-auth")
}
