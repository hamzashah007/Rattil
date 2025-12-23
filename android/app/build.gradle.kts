import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

/**
 * Load keystore properties from android/app/key.properties
 */
val keystoreProperties = Properties()
val keystorePropertiesFile = file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
} else {
    throw GradleException("key.properties file not found at ${keystorePropertiesFile.absolutePath}")
}

android {
    namespace = "com.hexait.rattil"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    packaging {
        jniLibs {
            useLegacyPackaging = false
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.hexait.rattil"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    /**
     * Release signing configuration (required for AAB)
     */
    signingConfigs {
        create("release") {
            val storeFilePath = keystoreProperties["storeFile"] as? String
                ?: throw GradleException("storeFile is missing in key.properties")
            val storePassword = keystoreProperties["storePassword"] as? String
                ?: throw GradleException("storePassword is missing in key.properties")
            val keyAlias = keystoreProperties["keyAlias"] as? String
                ?: throw GradleException("keyAlias is missing in key.properties")
            val keyPassword = keystoreProperties["keyPassword"] as? String
                ?: throw GradleException("keyPassword is missing in key.properties")

            storeFile = file(storeFilePath)
            this.storePassword = storePassword
            this.keyAlias = keyAlias
            this.keyPassword = keyPassword
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}
