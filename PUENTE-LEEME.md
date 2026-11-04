# Puente — escritorio remoto para Linux, Windows y Android

Puente es tu escritorio remoto estilo AnyDesk, con tu marca, construido sobre el motor de código abierto RustDesk 1.5.1 (Rust + Flutter, licencia AGPL‑3.0).

## Qué trae
- **Rápido sin perder calidad**: códec automático con aceleración por hardware (NVENC/QSV/AMF en Windows, VA‑API en Linux, MediaCodec en Android), **60 fps** y calidad **70 %** por defecto (en vez de 30 fps y 50 %). Se pueden cambiar en la barra de la sesión.
- Conexión P2P directa cuando es posible y relé por **tu propio servidor** cuando no.
- Cifrado de extremo a extremo, transferencia de archivos, portapapeles, audio, chat, varios monitores, acceso desatendido con contraseña.
- Diseño renovado: nombre **Puente**, icono nuevo y colores violeta/cian.

## Descargas
Cada push a la rama `puente` compila solo. Los archivos aparecen en **Releases → puente-ultima**:
- Windows: `rustdesk-1.5.1-x86_64.exe` (portable/instalable) y `.msi`
- Linux (Mint/Ubuntu/Debian): `rustdesk-1.5.1-x86_64.deb` → `sudo apt install ./rustdesk-1.5.1-x86_64.deb`
- Android: `puente-1.5.1-android.apk`

## Carpetas propias
- `puente/aplicar-marca.sh`: aplica nombre, colores, iconos y ajustes de rendimiento (ya aplicado; vuelve a usarlo si actualizas el código de RustDesk).
- `puente/servidor.conf`: la IP y la clave de tu servidor.
- `puente/firma/puente.jks`: clave de firma del APK (contraseña `puente-remoto`). Si lo cambias, las actualizaciones del APK no se instalarán encima de la versión anterior.
- `servidor/`: instalador del servidor propio (ver `servidor/LEEME.md`).

## Android: primera vez
Al compartir la pantalla del móvil, Android pedirá permiso de **captura de pantalla** y, para controlarlo a distancia, activar **Puente Input** en Ajustes → Accesibilidad.
