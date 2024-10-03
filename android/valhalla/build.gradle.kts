plugins {
    alias(libs.plugins.android.library)
    alias(libs.plugins.jetbrains.kotlin.android)
    alias(libs.plugins.ktfmt)
    `maven-publish`
}

android {
    namespace = "com.valhalla.valhalla"
    compileSdk = 34

    defaultConfig {
        minSdk = 26

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        consumerProguardFiles("consumer-rules.pro")
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }
    kotlinOptions {
        jvmTarget = "1.8"
    }
    publishing {
        singleVariant("release") {
            withSourcesJar()
            withJavadocJar()
        }
    }
}

dependencies {
    implementation(libs.core.ktx)

    implementation(libs.moshi.kotlin)
    implementation(libs.moshi.adapters)

    implementation(libs.valhalla.config)
    implementation(libs.valhalla.api)
    implementation(libs.osrm.api)

    testImplementation(libs.junit)

    androidTestImplementation(libs.androidx.test.ext.junit)
    androidTestImplementation(libs.androidx.test.core)
    androidTestImplementation(libs.androidx.test.runner)
    androidTestImplementation(libs.androidx.test.rules)
}

// Define a custom task to run the shell script
tasks.register<Exec>("buildLibValhalla") {

    // Command to execute your build.sh script
    commandLine("sh", "./build.sh", "android", "clean")

    // Ensure the submodule is initialized
    doFirst {
        exec {
            commandLine("git", "submodule", "update", "--init", "--recursive")
        }
    }

    val archs = listOf("arm64-v8a", "armeabi-v7a", "x86", "x86_64")
    outputs.files(archs.map { file("src/main/jniLibs/$it/libvalhalla-wrapper.so") })

    // Conditionally compile the library outputs don't exist.
    onlyIf {
        archs.any { arch ->
            !file("src/main/jniLibs/$arch/libvalhalla-wrapper.so").exists()
        }
    }
}

tasks.build {
    dependsOn("buildLibValhalla")
}

publishing {
    repositories {
        maven {
            name = "GitHubPackages"
            url = uri("https://maven.pkg.github.com/Rallista/valhalla-mobile")
            credentials {
                username = System.getenv("GITHUB_ACTOR")
                password = System.getenv("GITHUB_TOKEN")
            }
        }
    }

    publications {
        create<MavenPublication>("gpr") {
            afterEvaluate {
                from(components["release"])
            }

            groupId = "com.valhalla"
            artifactId = "valhalla"
            version = "0.0.1"
        }
    }
}