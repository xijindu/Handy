import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// 从 android/key.properties 读取签名信息（该文件与 jks 均不入库）
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// release 签名缺失时记录具体原因，构建 release 时直接报错，不回退到 debug 签名
val releaseSigningError: String? = run {
    if (!keystorePropertiesFile.exists()) {
        return@run "未找到 ${keystorePropertiesFile.absolutePath}：release 构建需要签名配置，请填写 storeFile、storePassword、keyAlias、keyPassword"
    }
    val missingKeys = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
        .filter { keystoreProperties.getProperty(it).isNullOrBlank() }
    if (missingKeys.isNotEmpty()) {
        return@run "android/key.properties 缺少字段：${missingKeys.joinToString(", ")}"
    }
    val storeFile = file(keystoreProperties.getProperty("storeFile"))
    if (!storeFile.exists()) {
        return@run "签名文件不存在：${storeFile.absolutePath}（key.properties 中的 storeFile 相对 android/app）"
    }
    null
}

// 仅 release 变体校验，debug 构建不受影响
gradle.taskGraph.whenReady {
    val error = releaseSigningError
    if (error != null && allTasks.any { it.name.endsWith("Release") }) {
        throw GradleException("Release 签名配置无效：$error")
    }
}

android {
    namespace = "org.handy.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "org.handy.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 26  // Android 8.0
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // All Flutter-supported ABIs (disable-abi-filtering in gradle.properties prevents
        // Flutter from injecting its own default ndk abiFilters)
        ndk {
            abiFilters += listOf("arm64-v8a", "armeabi-v7a", "x86_64")
        }
    }

    signingConfigs {
        if (releaseSigningError == null) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // 签名缺失时不回退 debug，交由上面的 taskGraph 校验直接报错
            signingConfig = signingConfigs.findByName("release")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
