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
s = re.sub(r'android:label="[^"]*"', 'android:label="الدكان"', s, count=1)
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
plugin_decl = '    id("com.google.gms.google-services") version "4.4.2" apply false'
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

