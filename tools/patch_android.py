#!/usr/bin/env python3
"""Patches the generated Android manifest and Gradle release signing."""
import re
import sys
from pathlib import Path

manifest = Path(sys.argv[1] if len(sys.argv) > 1 else "android/app/src/main/AndroidManifest.xml")
s = manifest.read_text(encoding="utf-8")
perms = [
    "android.permission.INTERNET",
    "android.permission.ACCESS_FINE_LOCATION",
    "android.permission.ACCESS_COARSE_LOCATION",
]
add = "".join(f'    <uses-permission android:name="{p}"/>\n' for p in perms if p not in s)
if add:
    s = s.replace("<application", add + "    <application", 1)
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

gradle = Path("android/app/build.gradle.kts")
if not gradle.exists():
    raise SystemExit("Expected android/app/build.gradle.kts was not generated")
g = gradle.read_text(encoding="utf-8")
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
gradle.write_text(g, encoding="utf-8")
print("Patched Android manifest and release signing configuration")
