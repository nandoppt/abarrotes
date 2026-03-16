plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}
dependencies {
    implementation("com.google.android.gms:play-services-ads:24.4.0")
}
android {
    namespace = "com.tienditaapp.abarrotes"
    compileSdk = 35
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.tienditaapp.abarrotes"
        minSdk = 24
        targetSdk = 35
        versionCode = 1 // Incrementa con cada actualización
        versionName = "1.0.0"
    }

    signingConfigs {
        create("release") {
            storeFile = file("keystore.jks")
            storePassword = "live-1990A"  // Reemplázala
            keyAlias = "tiendita"             // El alias que usaste
            keyPassword = "live-1990A"   // Misma que storePassword
        }
    }

    buildTypes {
            release {
                isMinifyEnabled = true
                isShrinkResources = true
                proguardFiles(
                    getDefaultProguardFile("proguard-android-optimize.txt"),
                    "proguard-rules.pro"
                )
                // La firma se configurará después
                signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}
