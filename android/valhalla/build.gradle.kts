import com.github.javaparser.utils.ProjectRoot

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
    // Change the working door to the repository root.
    workingDir = file("${project.projectDir}/../../")

    // Set the VCPKG_ROOT environment variable.
    environment("VCPKG_ROOT", "${workingDir.absolutePath}/vcpkg")

    // Command to execute your build.sh script.
    commandLine("sh", "./build.sh", "android", "clean")

    // Conditionally compile the library outputs don't exist.
    val archs = listOf("arm64-v8a", "armeabi-v7a", "x86", "x86_64")
    onlyIf {
        archs.any { arch ->
            !file("src/main/jniLibs/$arch/libvalhalla-wrapper.so").exists()
        }
    }
}

tasks.named("preBuild") {
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
