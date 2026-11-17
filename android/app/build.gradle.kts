import java.util.Properties
import groovy.json.JsonSlurper

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

val signingProperties = Properties()
val signingFile = rootProject.file("key.properties")
if (signingFile.exists()) signingFile.inputStream().use { signingProperties.load(it) }
val hasReleaseSigning = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
    .all { !signingProperties.getProperty(it).isNullOrBlank() }

val ads = JsonSlurper().parse(rootProject.file("../assets/config/admob.json")) as Map<*, *>
val testAppId = ads["androidTestAppId"] as String
val productionAds = ads["useProductionAds"] == true
val releaseAppId = if (productionAds) ads["androidProductionAppId"] as String else testAppId
if (productionAds && (releaseAppId.isBlank() || (ads["androidProductionRewardedId"] as String).isBlank())) {
    throw GradleException("assets/config/admob.json içindeki gerçek reklam ID'lerini doldurun.")
}

android {
    namespace = "com.tansiyonsekerdefterim.app"
    compileSdk = 36
    ndkVersion = "28.2.13676358"
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = "17" }
    defaultConfig {
        applicationId = "com.tansiyonsekerdefterim.app"
        minSdk = providers.gradleProperty("app.minSdk").get().toInt()
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["admobAppId"] = testAppId
    }
    signingConfigs {
        if (hasReleaseSigning) create("release") {
            storeFile = file(signingProperties.getProperty("storeFile"))
            storePassword = signingProperties.getProperty("storePassword")
            keyAlias = signingProperties.getProperty("keyAlias")
            keyPassword = signingProperties.getProperty("keyPassword")
        }
    }
    buildTypes {
        debug { manifestPlaceholders["admobAppId"] = testAppId }
        release {
            manifestPlaceholders["admobAppId"] = releaseAppId
            if (hasReleaseSigning) signingConfig = signingConfigs.getByName("release")
        }
    }
}

// Release hiçbir zaman debug anahtarıyla imzalanmaz.
gradle.taskGraph.whenReady {
    if (allTasks.any { it.project == project && it.name.contains("Release") } && !hasReleaseSigning) {
        throw GradleException("Release için android/key.properties dosyasını doldurun (örnek: key.properties.example).")
    }
}

flutter { source = "../.." }
