plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.speechmate.speechmate"
    compileSdk = 34  // Updated to latest stable
    ndkVersion = "27.0.12077973"  // Fixed NDK version

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.speechmate.speechmate"
        minSdk = 21  // Android 5.0 (Lollipop) - supports old devices
        targetSdk = 34  // Latest stable Android
        versionCode = 1
        versionName = "1.2.0"
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
