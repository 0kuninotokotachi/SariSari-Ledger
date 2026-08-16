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

// Workaround for older packages that don't declare an Android `namespace`,
// which recent AGP versions require, and that also pin an outdated
// compileSdk incompatible with current androidx transitive dependencies.
// Backfills the namespace from the package's own AndroidManifest.xml, and
// matches compileSdk to :app's. Uses reflection so this compiles even though
// AGP classes aren't on this script's classpath.
fun getAppCompileSdk(rootProject: Project): Int? {
    val appProject = rootProject.findProject(":app") ?: return null
    val androidExt = appProject.extensions.findByName("android") ?: return null
    val getter = androidExt.javaClass.methods.find { it.name == "getCompileSdk" && it.parameterCount == 0 } ?: return null
    return getter.invoke(androidExt) as? Int
}

fun backfillAndroidConfig(project: Project) {
    val androidExt = project.extensions.findByName("android") ?: return
    val getNamespace = androidExt.javaClass.methods.find { it.name == "getNamespace" } ?: return
    if (getNamespace.invoke(androidExt) != null) return

    val manifestFile = project.file("src/main/AndroidManifest.xml")
    if (manifestFile.exists()) {
        val packageName = Regex("package=\"([^\"]+)\"").find(manifestFile.readText())?.groupValues?.get(1)
        if (packageName != null) {
            val setNamespace = androidExt.javaClass.methods.find { it.name == "setNamespace" }
            setNamespace?.invoke(androidExt, packageName)
        }
    }

    val appCompileSdk = getAppCompileSdk(project.rootProject) ?: 36
    val setCompileSdkVersion = androidExt.javaClass.methods.find {
        it.name == "setCompileSdkVersion" && it.parameterTypes.size == 1 && it.parameterTypes[0] == Int::class.javaPrimitiveType
    }
    setCompileSdkVersion?.invoke(androidExt, appCompileSdk)
}

subprojects {
    // :app is eagerly evaluated above via evaluationDependsOn, so afterEvaluate
    // would throw on it — run immediately in that case instead.
    if (project.state.executed) {
        backfillAndroidConfig(project)
    } else {
        afterEvaluate { backfillAndroidConfig(project) }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
