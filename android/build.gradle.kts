allprojects {
    repositories {
        google()
        mavenCentral()
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

// Agrega esto al final de tu archivo android/build.gradle.kts

subprojects {
    val project = this
    // Escuchamos cuando se agregue cualquier plugin al subproyecto
    project.plugins.whenPluginAdded {
        // Si el plugin es de Android (BasePlugin cubre Library y App)
        if (this is com.android.build.gradle.api.AndroidBasePlugin) {
            project.extensions.configure<com.android.build.gradle.BaseExtension> {
                // Si el namespace está vacío (como en isar_flutter_libs), lo forzamos
                if (namespace == null) {
                    namespace = project.group.toString()
                }
            }
        }
    }
}