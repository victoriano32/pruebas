# Brisa

Distribución Linux basada en Ubuntu 26.04 LTS con escritorio KDE Plasma 6, pensada para ser muy personalizable. Esta primera versión (0.1) está hecha para usarse desde un USB con persistencia.

"Brisa" es un nombre provisional: se cambia en `config/distro.conf`.

## Qué trae la versión 0.1

- KDE Plasma 6.6 en español, con teclado español y zona horaria de Madrid.
- Tres disposiciones de panel: dock flotante, barra flotante y barra superior con dock.
- Galería de 10 iconos para el botón de menú, y opción de usar una imagen propia.
- App "Personalizar Brisa": panel, icono del menú, tema de iconos, modo claro u oscuro y color de acento. Se abre sola en el primer arranque.
- Packs de iconos Papirus, Tela y Fluent, además de Breeze. Kvantum y varios cursores y fuentes.
- Firefox (desde el repositorio de Mozilla), LibreOffice, VLC y códecs multimedia.
- Tienda Discover con Flatpak y Flathub. Sin Snap.
- KDE Connect, impresoras y escáneres (HP incluido), Timeshift.
- Arranque en BIOS y UEFI.

## Qué falta todavía

- Instalador en disco duro (Calamares).
- Repositorio propio para actualizar la parte de Brisa.
- Pantalla de arranque propia y tema de inicio de sesión propio.
- Tus aplicaciones: copia sus `.deb` en `debs/` y se instalan al compilar.

## Cómo se compila

### En GitHub

Cada vez que se sube un cambio, GitHub compila la ISO sola (pestaña **Actions**, flujo "Compilar ISO"). Al terminar, la ISO se descarga desde la sección **Artifacts** de esa ejecución, dentro de un zip.

El repositorio debe ser **público**: en uno privado el plan gratuito de GitHub solo guarda 500 MB de resultados y la ISO ocupa varios GB.

### En tu equipo (Ubuntu, Mint o Debian)

```bash
sudo ./build.sh
```

Necesita unos 25 GB libres y tarda entre 30 y 60 minutos. La ISO queda en `salida/`.

## Cómo crear el USB con persistencia

Con un USB de 16 GB o más (mejor 32 GB o más, y USB 3):

```bash
sudo apt install gdisk parted
lsblk                          # para ver qué dispositivo es el USB, por ejemplo /dev/sdb
sudo ./herramientas/crear-usb.sh brisa-0.1-amd64.iso /dev/sdX
```

El script graba la ISO y usa el resto del USB como partición de persistencia. **Borra todo el USB.**

Alternativas: **Rufus** en Windows (deslizador "Tamaño de partición persistente"), **mkusb** en Linux, o **Ventoy** con su complemento de persistencia.

Al arrancar, la primera opción del menú guarda los cambios. Hay otra para arrancar sin guardar nada.

## Cómo personalizar la distro

| Qué | Dónde |
| --- | --- |
| Nombre, versión, idioma, icono de menú de serie | `config/distro.conf` |
| Programas instalados | `config/paquetes.list` |
| Disposiciones de panel | `overlay/usr/share/brisa/disposiciones/` |
| Iconos del botón de menú | `overlay/usr/share/icons/hicolor/scalable/apps/brisa-menu-*.svg` |
| Fondo de pantalla | `overlay/usr/share/wallpapers/Brisa/` |
| Tema global de serie | `overlay/usr/share/plasma/look-and-feel/org.brisa.desktop/` |
| App de personalización | `overlay/usr/bin/brisa-personalizar` |

Los paquetes de `paquetes.list` que no existan se omiten y quedan anotados en `salida/avisos.txt`.
