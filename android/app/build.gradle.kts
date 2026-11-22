import java.util.Base64
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

var dartEnvironmentVariables = mutableMapOf("publish" to false)

if (project.hasProperty("dart-defines")) {
    dartEnvironmentVariables.putAll(
            (project.property("dart-defines") as String).split(',').associate { entry ->
                val pair = String(Base64.getDecoder().decode(entry)).split('=')
                pair.first() to (pair.last() == "true")
            }
    )
}

android {
    namespace = "com.nebula.clashmi"
    compileSdkVersion = "android-35"
    buildToolsVersion = "36.0.0"
    ndkVersion = "28.2.13676358" // flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions { jvmTarget = JavaVersion.VERSION_17.toString() }

    defaultConfig {
        applicationId = "com.nebula.clashmi"
        minSdk = 26
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        val keystore = rootProject.file("./key.properties")
        val prop = Properties().apply { keystore.inputStream().use(this::load) }
        named("debug") {
            applicationIdSuffix = ".dashboard"
            ndk { abiFilters += listOf("armeabi-v7a", "arm64-v8a", "x86_64", "x86") }
        }
        named("profile") {
            applicationIdSuffix = ".dashboard"
            signingConfig =
                    signingConfigs.create("profile") {
                        storeFile = rootProject.file(prop.getProperty("storeFile.release"))
                        storePassword = prop.getProperty("storePassword.release")
                        keyAlias = prop.getProperty("keyAlias.release")
                        keyPassword = prop.getProperty("keyPassword.release")
                    }
            ndk { abiFilters += listOf("armeabi-v7a", "arm64-v8a", "x86_64", "x86") }
        }
        named("release") {
            applicationIdSuffix = ".dashboard"
            val releaseKeystorePath = System.getenv("CLASHMI_RELEASE_KEYSTORE")
            val releaseStorePassword = System.getenv("CLASHMI_RELEASE_STORE_PASSWORD")
            val releaseKeyAlias = System.getenv("CLASHMI_RELEASE_KEY_ALIAS")
            val releaseKeyPassword = System.getenv("CLASHMI_RELEASE_KEY_PASSWORD")
            signingConfig =
                    if (!releaseKeystorePath.isNullOrBlank() &&
                                    !releaseStorePassword.isNullOrBlank() &&
                                    !releaseKeyAlias.isNullOrBlank() &&
                                    !releaseKeyPassword.isNullOrBlank()) {
                        signingConfigs.create("dashboardRelease") {
                            storeFile = file(releaseKeystorePath)
                            storePassword = releaseStorePassword
                            keyAlias = releaseKeyAlias
                            keyPassword = releaseKeyPassword
                        }
                    } else {
                        signingConfigs.getByName("debug")
                    }
            ndk {
                abiFilters.clear()
                abiFilters += listOf("arm64-v8a")
                // debugSymbolLevel = 'FULL'
            }
        }
    }
    splits {
        abi {
            isEnable = false
            isUniversalApk = false
        }
    }
}

androidComponents {
    onVariants { variant ->
        if (variant.buildType == "release") {
            variant.packaging.jniLibs.excludes.add("**/x86_64/**")
        }
    }
}

flutter { source = "../.." }

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("androidx.browser:browser:1.8.0")
}

configurations.configureEach {
    resolutionStrategy.force(
            "androidx.browser:browser:1.8.0",
            "androidx.core:core:1.15.0",
            "androidx.core:core-ktx:1.15.0",
            "androidx.activity:activity:1.9.3",
            "androidx.activity:activity-ktx:1.9.3",
    )
}
