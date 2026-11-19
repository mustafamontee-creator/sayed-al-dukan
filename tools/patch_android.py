#!/usr/bin/env python3
"""Patches the generated Android manifest, Firebase plugins, and release signing."""
import re
import sys
from pathlib import Path

manifest = Path(sys.argv[1] if len(sys.argv) > 1 else "android/app/src/main/AndroidManifest.xml")
s = manifest.read_text(encoding="utf-8")
perms = [
    "android.permission.INTERNET",
    "android.permission.POST_NOTIFICATIONS",
    "android.permission.REQUEST_INSTALL_PACKAGES",
    "android.permission.ACCESS_FINE_LOCATION",
    "android.permission.ACCESS_COARSE_LOCATION",
]
add = "".join(f'    <uses-permission android:name="{p}"/>\n' for p in perms if p not in s)
if add:
    s = s.replace("<application", add + "    <application", 1)

# Route background FCM notifications to the app's high-priority updates channel.
if "com.google.firebase.messaging.default_notification_channel_id" not in s:
    app_start = s.find("<application")
    app_end = s.find(">", app_start)
    if app_start < 0 or app_end < 0:
        raise SystemExit("Could not locate Android application tag")
    metadata = chr(10) + (
        '        <meta-data android:name="com.google.firebase.messaging.default_notification_channel_id" '
        'android:value="app_updates"/>'
    ) + chr(10) + (
        '        <meta-data android:name="com.google.firebase.messaging.default_notification_icon" '
        'android:resource="@mipmap/ic_launcher"/>'
    )
    s = s[:app_end + 1] + metadata + s[app_end + 1:]
s = re.sub(r'android:label="[^"]*"', 'android:label="سيد الدكان"', s, count=1)
s = re.sub(r'\s*<meta-data\s+android:name="com\.google\.android\.geo\.API_KEY"[^>]*/>\s*', '\n', s)
if "login-callback" not in s:
    intent = (
        '            <intent-filter>\n'
        '                <action android:name="android.intent.action.VIEW"/>\n'
        '                <category android:name="android.intent.category.DEFAULT"/>\n'
        '                <category android:name="android.intent.category.BROWSABLE"/>\n'
        '                <data android:scheme="io.supabase.sayedaldukan" android:host="login-callback"/>\n'
        '            </intent-filter>\n'
    )
    s = s.replace("</activity>", intent + "        </activity>", 1)
manifest.write_text(s, encoding="utf-8")

# Firebase Google Services plugin: declare version in settings, apply in app module.
settings = Path("android/settings.gradle.kts")
if not settings.exists():
    raise SystemExit("Expected android/settings.gradle.kts was not generated")
st = settings.read_text(encoding="utf-8")
plugin_decl = '    id("com.google.gms.google-services") version "4.6.0" apply false'
if "com.google.gms.google-services" not in st:
    match = re.search(r"plugins\s*\{", st)
    if not match:
        raise SystemExit("Could not locate plugins block in settings.gradle.kts")
    pos = match.end()
    st = st[:pos] + "\n" + plugin_decl + st[pos:]
settings.write_text(st, encoding="utf-8")

gradle = Path("android/app/build.gradle.kts")
if not gradle.exists():
    raise SystemExit("Expected android/app/build.gradle.kts was not generated")
g = gradle.read_text(encoding="utf-8")
if 'id("com.google.gms.google-services")' not in g:
    match = re.search(r'plugins\s*\{', g)
    if not match:
        raise SystemExit("Could not locate plugins block in app build.gradle.kts")
    pos = match.end()
    g = g[:pos] + '\n    id("com.google.gms.google-services")' + g[pos:]
if 'create("release")' not in g:
    signing = '''
    signingConfigs {
        create("release") {
            storeFile = file(System.getenv("ANDROID_KEYSTORE_PATH") ?: "release-key.p12")
            storePassword = System.getenv("ANDROID_KEYSTORE_PASSWORD") ?: ""
            keyAlias = System.getenv("ANDROID_KEY_ALIAS") ?: "sayed-al-dukan-release"
            keyPassword = System.getenv("ANDROID_KEY_PASSWORD") ?: ""
        }
    }

'''
    if "    buildTypes {" not in g:
        raise SystemExit("Could not locate buildTypes in generated Gradle file")
    g = g.replace("    buildTypes {", signing + "    buildTypes {", 1)
g = g.replace('signingConfig = signingConfigs.getByName("debug")',
              'signingConfig = signingConfigs.getByName("release")')
# flutter_local_notifications requires Java 8+ API desugaring on Android.
if "isCoreLibraryDesugaringEnabled" not in g:
    compile_block = re.search(r"compileOptions\s*\{", g)
    if compile_block:
        block_end = g.find("}", compile_block.end())
        if block_end < 0:
            raise SystemExit("Could not locate end of compileOptions block")
        g = g[:block_end] + "        isCoreLibraryDesugaringEnabled = true\n    " + g[block_end:]
    else:
        android_block = re.search(r"android\s*\{", g)
        if not android_block:
            raise SystemExit("Could not locate android block in generated Gradle file")
        addition = "\n    compileOptions {\n        isCoreLibraryDesugaringEnabled = true\n    }\n"
        g = g[:android_block.end()] + addition + g[android_block.end():]
if "coreLibraryDesugaring(" not in g:
    dep_block = re.search(r"dependencies\s*\{", g)
    dependency = '\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")'
    if dep_block:
        g = g[:dep_block.end()] + dependency + g[dep_block.end():]
    else:
        g += '\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")\n}\n'
gradle.write_text(g, encoding="utf-8")
print("Patched Android manifest, Firebase plugins, and release signing configuration")

# Add a native FileProvider-backed installer channel for downloaded APKs.
app_tag = '<application'
provider = '''\n        <provider android:name="androidx.core.content.FileProvider"\n            android:authorities="com.sayedaldukan.sayed_al_dukan.updateprovider"\n            android:exported="false" android:grantUriPermissions="true">\n            <meta-data android:name="android.support.FILE_PROVIDER_PATHS"\n                android:resource="@xml/update_file_paths"/>\n        </provider>\n'''
if "updateprovider" not in s:
    s = s.replace("</application>", provider + "    </application>", 1)
manifest.write_text(s, encoding="utf-8")
xml_dir = Path("android/app/src/main/res/xml")
xml_dir.mkdir(parents=True, exist_ok=True)
(xml_dir / "update_file_paths.xml").write_text('''<?xml version="1.0" encoding="utf-8"?>\n<paths xmlns:android="http://schemas.android.com/apk/res/android">\n    <cache-path name="updates" path="."/>\n</paths>\n''', encoding="utf-8")
main_files = list(Path("android/app/src/main").rglob("MainActivity.kt"))
if len(main_files) != 1:
    raise SystemExit(f"Expected one generated MainActivity.kt, found {len(main_files)}")
main = main_files[0]
k = main.read_text(encoding="utf-8")
imports = [
    "import android.content.Intent",
    "import android.net.Uri",
    "import android.provider.Settings",
    "import androidx.core.content.FileProvider",
    "import io.flutter.embedding.engine.FlutterEngine",
    "import io.flutter.plugin.common.MethodChannel",
    "import java.io.File",
]
# Insert imports after the package declaration without relying on an exact Flutter import string.
package_match = re.search(r"^package [^\n]+\n", k, re.MULTILINE)
if not package_match:
    raise SystemExit("Could not find package declaration in generated MainActivity.kt")
missing_imports = [line for line in imports if line not in k]
if missing_imports:
    k = k[:package_match.end()] + "\n" + "\n".join(missing_imports) + k[package_match.end():]
if "sayed_al_dukan/apk_installer" not in k:
    method = '''
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "sayed_al_dukan/apk_installer").setMethodCallHandler { call, result ->
            if (call.method != "installApk") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            try {
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O &&
                    !packageManager.canRequestPackageInstalls()) {
                    val settingsIntent = Intent(
                        Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                        Uri.parse("package:" + packageName)
                    ).apply { addFlags(Intent.FLAG_ACTIVITY_NEW_TASK) }
                    startActivity(settingsIntent)
                    result.error("PERMISSION_REQUIRED", "Allow installing unknown apps, then return and tap Update now again.", null)
                    return@setMethodCallHandler
                }
                val path = call.argument<String>("path")
                    ?: throw IllegalArgumentException("Missing APK path")
                val apk = File(path)
                if (!apk.isFile || apk.length() < 1048576L) {
                    throw IllegalArgumentException("APK file missing or incomplete")
                }
                val uri = FileProvider.getUriForFile(
                    this,
                    "com.sayedaldukan.sayed_al_dukan.updateprovider",
                    apk
                )
                val intent = Intent(Intent.ACTION_VIEW).apply {
                    setDataAndType(uri, "application/vnd.android.package-archive")
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                }
                startActivity(intent)
                result.success(true)
            } catch (e: Exception) {
                result.error("INSTALL_FAILED", e.message, null)
            }
        }
    }
'''
    # Insert immediately before the class's final closing brace.
    class_end = k.rfind("\n}")
    if class_end < 0:
        raise SystemExit("Could not locate MainActivity class closing brace")
    k = k[:class_end] + "\n" + method + k[class_end:]
main.write_text(k, encoding="utf-8")
