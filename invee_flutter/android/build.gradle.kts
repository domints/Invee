allprojects {
    repositories {
        google()
        mavenCentral()
    }

    // Ensure all subprojects (including Flutter plugins) use the same KGP version
    // declared in settings.gradle.kts, avoiding version conflicts when a plugin
    // such as mobile_scanner applies KGP in its own build script.
    configurations.all {
        resolutionStrategy.eachDependency {
            if (requested.group == "org.jetbrains.kotlin" && requested.name.startsWith("kotlin-")) {
                useVersion("2.3.20")
                because("Align all Kotlin artefacts to the version declared in settings.gradle.kts")
            }
        }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
