plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "solutionbowl.com.safee_meet"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "solutionbowl.com.safee_meet"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    // didit_sdk's org.bouncycastle:bcprov-jdk18on and org.jspecify:jspecify
    // both bundle an identical-path multi-release JAR manifest entry, which
    // fails the resource merge step with "2 files found with path
    // META-INF/versions/9/OSGI-INF/MANIFEST.MF" — take either copy, the
    // content is interchangeable.
    packaging {
        resources {
            pickFirsts += "META-INF/versions/9/OSGI-INF/MANIFEST.MF"
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // Required for flutter_stripe: MainActivity's theme must derive from
    // Theme.MaterialComponents (see styles.xml) or Stripe's Android SDK
    // fails to initialize.
    implementation("com.google.android.material:material:1.12.0")
}

// didit_sdk's native Android SDK pulls in the newer, unified
// org.bouncycastle:bcprov-jdk18on, which duplicates classes with the older
// bcprov-jdk15to18 pulled in transitively elsewhere in the dependency graph
// (Google Play Services/Firebase) — causing a "Duplicate class" build
// failure. Both provide the same BouncyCastle classes, so drop the older one
// and let jdk18on win everywhere.
configurations.all {
    exclude(group = "org.bouncycastle", module = "bcprov-jdk15to18")
}

flutter {
    source = "../.."
}
