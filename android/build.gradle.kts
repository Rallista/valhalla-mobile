import java.util.regex.Pattern

// Top-level build file where you can add configuration options common to all sub-projects/modules.
plugins {
    alias(libs.plugins.android.library) apply false
    alias(libs.plugins.jetbrains.kotlin.android) apply false
}

fun getSharedVersion(): String {
    val text = file("../version.txt").readText().trim()
    val semVerPattern = Pattern.compile("^(0|[1-9]\\d*)\\.(0|[1-9]\\d*)\\.(0|[1-9]\\d*)(?:-((?:0|[1-9]\\d*|\\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\\.(?:0|[1-9]\\d*|\\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\\+([0-9a-zA-Z-]+(?:\\.[0-9a-zA-Z-]+)*))?$")

    if (!semVerPattern.matcher(text).matches()) {
        throw IllegalArgumentException("The version string '$text' is not a valid semantic version.")
    }

    print("Shared project version: $text")
    return text
}

allprojects {
    version = getSharedVersion()
}
