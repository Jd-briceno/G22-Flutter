plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android") // mejor práctica para Kotlin DSL
    id("dev.flutter.flutter-gradle-plugin") // plugin de Flutter
    id("com.google.gms.google-services") // Firebase
}

android {
    namespace = "com.example.melodymuse"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11

        // ✅ Sintaxis correcta en Kotlin DSL
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.melodymuse"
        minSdk = 24 // Firebase Auth requiere minSdk 23 o superior
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
    // 🔹 BOM de Firebase (controla las versiones automáticamente)
    implementation(platform("com.google.firebase:firebase-bom:34.3.0"))

    // 🔹 Dependencias de Firebase
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-auth")

    // ✅ Desugaring (sintaxis Kotlin DSL)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
