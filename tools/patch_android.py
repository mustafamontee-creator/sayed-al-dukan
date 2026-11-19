#!/usr/bin/env python3
"""Patches the Flutter-generated AndroidManifest.xml (permissions,
OAuth deep link and app name). Idempotent."""
import re
import sys

path = sys.argv[1] if len(sys.argv) > 1 else "android/app/src/main/AndroidManifest.xml"
with open(path, encoding="utf-8") as f:
    s = f.read()

perms = [
    "android.permission.INTERNET",
    "android.permission.ACCESS_FINE_LOCATION",
    "android.permission.ACCESS_COARSE_LOCATION",
]
add = "".join(f'    <uses-permission android:name="{p}"/>\n' for p in perms if p not in s)
if add:
    s = s.replace("<application", add + "    <application", 1)

s = re.sub(r'android:label="[^"]*"', 'android:label="الدكان"', s, count=1)

# Remove an obsolete Google Maps key entry if this project was previously generated.
s = re.sub(
    r'\s*<meta-data\s+android:name="com\.google\.android\.geo\.API_KEY"[^>]*/>\s*',
    '\n',
    s,
)

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

with open(path, "w", encoding="utf-8") as f:
    f.write(s)
print("patched", path)
