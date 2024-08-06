pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
        maven("https://maven.pkg.github.com/stadiamaps/osrm-openapi") {
            credentials {
                username = if (settings.extra.has("gpr.user")) settings.extra["gpr.user"] as String else System.getenv("GITHUB_ACTOR")
                password = if (settings.extra.has("gpr.token")) settings.extra["gpr.token"] as String else System.getenv("GITHUB_TOKEN")
            }
        }
        maven("https://maven.pkg.github.com/Rallista/valhalla-openapi-models-kotlin") {
            credentials {
                username = if (settings.extra.has("gpr.user")) settings.extra["gpr.user"] as String else System.getenv("GITHUB_ACTOR")
                password = if (settings.extra.has("gpr.token")) settings.extra["gpr.token"] as String else System.getenv("GITHUB_TOKEN")
            }
        }
    }
}

rootProject.name = "valhalla"
include(":valhalla")
