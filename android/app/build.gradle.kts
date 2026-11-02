import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ---------------------------------------------------------------------------
// Chữ ký release.
//
// Đọc từ android/keystore.properties — file này KHÔNG commit (đã nằm trong
// .gitignore). Thiếu nó thì build vẫn chạy bằng debug key để `flutter run
// --release` và PR từ fork không bị chặn, nhưng APK ký debug key không phải
// bản phát hành: mỗi runner CI sinh một debug keystore ngẫu nhiên khác nhau,
// nên người dùng không cài đè được bản mới và phải gỡ cài đặt, mất dữ liệu
// local. Xem docs/release-signing.md để tạo keystore và cài secret CI.
//
// Đường dẫn storeFile được hiểu tương đối với thư mục android/.
// ---------------------------------------------------------------------------
val keystorePropertiesFile: File = rootProject.file("keystore.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        keystorePropertiesFile.inputStream().use { load(it) }
    }
}

val releaseStoreFile: File? = keystoreProperties.getProperty("storeFile")
    ?.let { rootProject.file(it) }
    ?.takeIf { it.exists() }

val hasReleaseKeystore: Boolean =
    releaseStoreFile != null &&
        keystoreProperties.getProperty("storePassword") != null &&
        keystoreProperties.getProperty("keyAlias") != null &&
        keystoreProperties.getProperty("keyPassword") != null

if (!hasReleaseKeystore) {
    logger.warn(
        "Pixket: khong thay keystore.properties -> release build ky bang debug key. " +
            "Ban nay khong dung de phanh hanh. Xem docs/release-signing.md."
    )
}

android {
    namespace = "com.pixket.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    signingConfigs {
        create("release") {
            if (hasReleaseKeystore) {
                storeFile = releaseStoreFile
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.pixket.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Debug key chỉ là fallback dev nội bộ; bản phát hành bắt buộc có
            // keystore.properties.
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            // R8 bật: làm APK khó dịch ngược hơn và giảm kích thước.
            // isShrinkResources vẫn TẮT có chủ đích — flutter_local_notifications
            // tham chiếu '@mipmap/ic_launcher' bằng chuỗi lúc runtime, và resource
            // shrinking loại những tài nguyên static analysis coi là không dùng.
            isMinifyEnabled = true
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
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

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
