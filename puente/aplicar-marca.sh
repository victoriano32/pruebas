#!/usr/bin/env bash
# Aplica la marca "Puente" y los ajustes de rendimiento sobre el código de RustDesk.
# Uso: ./puente/aplicar-marca.sh  (desde la raíz del código)
set -euo pipefail
ROOT="$(pwd)"
B="$ROOT/puente/branding"
CFG="$ROOT/libs/hbb_common/src/config.rs"

echo "== Nombre de la app"
sed -i 's|APP_NAME: RwLock<String> = RwLock::new("RustDesk".to_owned())|APP_NAME: RwLock<String> = RwLock::new("Puente".to_owned())|' "$CFG"
sed -i 's|android:label="RustDesk"|android:label="Puente"|; s|android:label="RustDesk Input"|android:label="Puente Input"|' flutter/android/app/src/main/AndroidManifest.xml
sed -i 's|applicationId "com.carriez.flutter_hbb"|applicationId "es.puente.remoto"|' flutter/android/app/build.gradle
sed -i 's|^Name=RustDesk|Name=Puente|; s|^GenericName=Remote Desktop|GenericName=Escritorio remoto|' res/rustdesk.desktop res/rustdesk-link.desktop
sed -i 's|"RustDesk Remote Desktop"|"Puente Escritorio Remoto"|; s|VALUE "ProductName", "RustDesk"|VALUE "ProductName", "Puente"|' flutter/windows/runner/Runner.rc

echo "== Rendimiento y calidad por defecto (60 fps, calidad 70%, códec automático/hardware)"
sed -i 's|self.get_string(key, "balanced", vec!\["best", "low", "custom"\])|self.get_string(key, "custom", vec!["best", "balanced", "low"])|' "$CFG"
sed -i 's|keys::OPTION_CUSTOM_IMAGE_QUALITY => self.get_num_string(key, 50.0,|keys::OPTION_CUSTOM_IMAGE_QUALITY => self.get_num_string(key, 70.0,|' "$CFG"
sed -i 's|keys::OPTION_CUSTOM_FPS => self.get_num_string(key, 30.0,|keys::OPTION_CUSTOM_FPS => self.get_num_string(key, 60.0,|' "$CFG"
sed -i '/fn default_custom_image_quality/,/^    }/ s|unwrap_or(50.0)|unwrap_or(70.0)|' "$CFG"

echo "== Colores del tema (violeta/cian)"
C=flutter/lib/common.dart
sed -i 's|Color(0xFF0071FF)|Color(0xFF6A5CFF)|; s|Color(0x770071FF)|Color(0x776A5CFF)|; s|Color(0xAA0071FF)|Color(0xAA6A5CFF)|; s|Color(0xFF2C8CFF)|Color(0xFF6A5CFF)|; s|Color(0xFF00B6F0)|Color(0xFF00B8FF)|' "$C"
sed -i 's|<color name="ic_launcher_background">#ffffff</color>|<color name="ic_launcher_background">#5B5BF0</color>|' flutter/android/app/src/main/res/values/*.xml

echo "== Iconos"
png() { rsvg-convert -w "$2" -h "$2" "$B/$1.svg" -o "$3"; }
png icon 512 res/icon.png; png icon 32 res/32x32.png; png icon 64 res/64x64.png
png icon 128 res/128x128.png; png icon 256 res/128x128@2x.png; png icon 1024 res/mac-icon.png
cp "$B/icon.svg" flutter/assets/icon.svg; cp "$B/icon.svg" res/scalable.svg; cp "$B/icon.svg" res/logo.svg
T=$(mktemp -d)
for s in 16 24 32 48 64 128 256; do png icon $s "$T/$s.png"; done
convert "$T"/{16,24,32,48,64,128,256}.png res/icon.ico
convert "$T"/{16,24,32,48,64,128,256}.png flutter/windows/runner/resources/app_icon.ico
convert "$T"/{16,24,32,48}.png res/tray-icon.ico
A=flutter/android/app/src/main/res
for d in mdpi:48:108:24 hdpi:72:162:36 xhdpi:96:216:48 xxhdpi:144:324:72 xxxhdpi:192:432:96; do
  IFS=: read n l f s <<<"$d"
  png icon "$l" "$A/mipmap-$n/ic_launcher.png"
  png round "$l" "$A/mipmap-$n/ic_launcher_round.png"
  png fg "$f" "$A/mipmap-$n/ic_launcher_foreground.png"
  png mono "$s" "$A/mipmap-$n/ic_stat_logo.png"
done
rm -rf "$T"
echo "Marca aplicada."
