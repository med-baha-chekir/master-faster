allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir = File(rootProject.projectDir.parentFile, "build")
rootProject.buildDir = newBuildDir

subprojects {
    project.evaluationDependsOn(":app")
    
    val pluginDrive = project.projectDir.absolutePath.substringBefore(":")
    val rootDrive = rootProject.projectDir.absolutePath.substringBefore(":")
    
    if (pluginDrive.equals(rootDrive, ignoreCase = true)) {
        project.buildDir = File(newBuildDir, project.name)
    } else {
        // Workaround for KGP "different roots" bug across Windows drives:
        // Place the build directory on the same drive as the plugin source (assumed C: for Pub Cache).
        // Using java.io.tmpdir ensures we have write permissions.
        project.buildDir = File(System.getProperty("java.io.tmpdir"), "voicebridge_build/${project.name}")
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}