import com.vanniktech.maven.publish.AndroidSingleVariantLibrary
import com.vanniktech.maven.publish.SonatypeHost

plugins {
    alias(libs.plugins.android.library)
    alias(libs.plugins.jetbrains.kotlin.android)
    alias(libs.plugins.ktfmt)
    alias(libs.plugins.mavenPublish)
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
}

dependencies {
    implementation(libs.core.ktx)

    implementation(libs.moshi.kotlin)
    implementation(libs.moshi.adapters)

    implementation(libs.valhalla.models.api)
    implementation(libs.valhalla.models.config)
    implementation(libs.osrm.api)

    testImplementation(libs.junit)

    androidTestImplementation(libs.androidx.test.ext.junit)
    androidTestImplementation(libs.androidx.test.core)
    androidTestImplementation(libs.androidx.test.runner)
    androidTestImplementation(libs.androidx.test.rules)
}

val archs = listOf("arm64-v8a", "armeabi-v7a", "x86_64", "x86")

// Define a custom task to run the shell script
archs.forEach { arch ->
    tasks.register<Exec>("buildValhallaFor-${arch}") {
        description = "Build libValhalla for $arch architecture"
        group = "build"

        // Change the working door to the repository root.
        workingDir = file("${project.projectDir}/../../")
        environment("VCPKG_ROOT", "${workingDir.absolutePath}/vcpkg")

        commandLine("bash", "./build.sh", "--android", arch)

        onlyIf {
            !file("src/main/jniLibs/${arch}/libvalhalla-wrapper.so").exists()
        }
    }
}

tasks.named("preBuild") {
    // Efficiently build any architecture that doesn't exist in jniLibs.
    dependsOn("buildValhallaFor-arm64-v8a")
    dependsOn("buildValhallaFor-armeabi-v7a")
    dependsOn("buildValhallaFor-x86_64")
    dependsOn("buildValhallaFor-x86")
}

mavenPublishing {
    publishToMavenCentral(SonatypeHost.CENTRAL_PORTAL)
    signAllPublications()

    if (project.version.toString() === "unspecified") {
        throw IllegalArgumentException("Version must be specified")
    }

    coordinates("io.github.rallista", "valhalla-mobile", project.version.toString())

    configure(AndroidSingleVariantLibrary(sourcesJar = true, publishJavadocJar = true))

    pom {
        name.set("Valhalla Mobile")
        url.set("https://github.com/Rallista/valhalla-mobile")
        description.set("A mobile app focused wrapper library for the valhalla routing engine")
        inceptionYear.set("2024")
        licenses {
            license {
                name.set("MIT")
                url.set("https://github.com/Rallista/valhalla-mobile?tab=MIT-1-ov-file#MIT-1-ov-file")
            }
        }
        developers {
            developer {
                name.set("Jacob Fielding")
                organization.set("Rallista")
                organizationUrl.set("https://rallista.app")
            }
        }
        contributors {
            contributor {
                name.set("Valhalla")
                organizationUrl.set("https://github.com/valhalla/valhalla")
            }
        }
        scm {
            connection.set("scm:git:https://github.com/Rallista/valhalla-mobile.git")
            developerConnection.set("scm:git:ssh://github.com/Rallista/valhalla-mobile.git")
            url.set("https://github.com/Rallista/valhalla-mobile")
        }
    }
}