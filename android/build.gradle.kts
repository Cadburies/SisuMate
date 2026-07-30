allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Workaround for "Namespace not specified" error in isar_flutter_libs with AGP 8+
subprojects {
    if (name == "isar_flutter_libs") {
        afterEvaluate {
            val android = project.extensions.findByName("android")
            if (android != null) {
                try {
                    android.javaClass.getMethod("setNamespace", String::class.java).invoke(android, "dev.isar.isar_flutter_libs")
                } catch (e: Exception) {
                    println("Failed to set namespace for isar_flutter_libs: ${e.message}")
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
