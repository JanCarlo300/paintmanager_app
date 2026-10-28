import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Chave de upload da Google Play: android/key.properties (fora do Git, ver
// android/.gitignore). Sem ela, só a versão debug compila; a release para com
// erro em vez de sair assinada com a chave debug, que a Play recusa.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

val pediuRelease = gradle.startParameter.taskNames.any { it.contains("release", ignoreCase = true) }
if (pediuRelease && !keystorePropertiesFile.exists()) {
    throw GradleException(
        "Build release sem chave de assinatura: crie android/key.properties " +
            "(storeFile, storePassword, keyAlias, keyPassword) apontando para a chave de upload.",
    )
}

android {
    namespace = "com.example.paintmanager_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    defaultConfig {
        // Identificador na Google Play: depois da primeira subida, nunca mais muda.
        // O namespace (pacote do código Kotlin) continua com.example.paintmanager_app.
        applicationId = "br.com.paintmanager.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = keystoreProperties["storeFile"]?.let { file(it) }
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Sem key.properties o build release já parou lá em cima.
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

// Kotlin 2.3: o antigo kotlinOptions { jvmTarget } virou compilerOptions.
kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11)
    }
}

flutter {
    source = "../.."
}
