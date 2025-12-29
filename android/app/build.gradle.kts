plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("com.google.gms.google-services")
    id("com.google.android.libraries.mapsplatform.secrets-gradle-plugin")
}

android {
    namespace = "com.treasuredata.pushsample"
    compileSdk = 34

    defaultConfig {
        // CUSTOMIZE: Change to your app's package name
        applicationId = "com.treasuredata.pushsample"
        minSdk = 26
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"

        // CUSTOMIZE: Deep link scheme configuration
        // Define a unique scheme for your app (e.g., "myapp", "yourcompany")
        // This will be used for deep links like "myapp://product/12345"
        buildConfigField("String", "DEEP_LINK_SCHEME", "\"tdpushsample\"")
        manifestPlaceholders["deepLinkScheme"] = "tdpushsample"

        // CUSTOMIZE: URL allowlist configuration (comma-separated domains)
        // Add domains that are allowed to be opened from push notifications
        // This is a security measure to prevent malicious links
        buildConfigField("String", "ALLOWED_DOMAINS", "\"example.com,treasuredata.com\"")

        // CUSTOMIZE: Deep link host allowlist (comma-separated hosts)
        // Define the hosts that your deep link routing supports
        // Example: "product,category,home" for "myapp://product/...", "myapp://category/...", etc.
        buildConfigField("String", "ALLOWED_DEEP_LINK_HOSTS", "\"product,category,home\"")
    }

    buildTypes {
        debug {
            buildConfigField("boolean", "ENABLE_LOGGING", "true")
        }
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            buildConfigField("boolean", "ENABLE_LOGGING", "false")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    buildFeatures {
        buildConfig = true
        viewBinding = true
    }
}

dependencies {
    // Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:34.7.0"))
    implementation("com.google.firebase:firebase-messaging")
    implementation("com.google.firebase:firebase-analytics")

    // AndroidX
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("com.google.android.material:material:1.11.0")
    implementation("androidx.constraintlayout:constraintlayout:2.1.4")

    // Lifecycle & Coroutines
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.6.2")
    implementation("androidx.lifecycle:lifecycle-viewmodel-ktx:2.6.2")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.8.1")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-play-services:1.8.1")

    // Background tasks
    implementation("androidx.work:work-runtime-ktx:2.9.1")

    // Treasure Data SDK
    implementation("com.treasuredata:td-android-sdk:1.1.0")

    // Web links
    implementation("androidx.browser:browser:1.8.0")

    // Testing
    testImplementation("junit:junit:4.13.2")
    androidTestImplementation("androidx.test.ext:junit:1.1.5")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.5.1")
}
