import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.onlygigz.musician"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.onlygigz.musician"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val keyPropsExist = keystorePropertiesFile.exists()
            keyAlias = if (keyPropsExist) keystoreProperties["keyAlias"] as String? ?: "upload" else "upload"
            keyPassword = if (keyPropsExist) keystoreProperties["keyPassword"] as String? ?: "onlygigz2026" else "onlygigz2026"
            val storeFilePath = if (keyPropsExist && keystoreProperties.containsKey("storeFile")) {
                keystoreProperties["storeFile"] as String
            } else {
                "upload-keystore.jks"
            }
            storeFile = file(storeFilePath)
            storePassword = if (keyPropsExist) keystoreProperties["storePassword"] as String? ?: "onlygigz2026" else "onlygigz2026"
        }
    }

    buildTypes {
        release {
            val releaseKeystore = file("upload-keystore.jks")
            signingConfig = if (releaseKeystore.exists() || keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}

tasks.whenTaskAdded {
    if (name == "assembleRelease") {
        doLast {
            val apkDir = file("${buildDir}/outputs/flutter-apk")
            val oldFile = file("${apkDir}/app-release.apk")
            val newFile = file("${apkDir}/OnlyGigz-Musician-v${android.defaultConfig.versionName}.apk")
            if (oldFile.exists()) {
                oldFile.renameTo(newFile)
                println("APK renamed to: ${newFile.name}")
            }
        }
    }
    if (name == "bundleRelease") {
        doLast {
            val bundleDir = file("${buildDir}/outputs/bundle/release")
            val oldFile = file("${bundleDir}/app-release.aab")
            val newFile = file("${bundleDir}/OnlyGigz-Musician-v${android.defaultConfig.versionName}.aab")
            if (oldFile.exists()) {
                oldFile.copyTo(newFile, overwrite = true)
                println("AAB copied to: ${newFile.name}")
            }
        }
    }
}

