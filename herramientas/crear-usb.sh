#!/usr/bin/env bash
# Graba la ISO en un USB y crea en el espacio sobrante una partición de persistencia,
# para que los archivos, ajustes y programas instalados se conserven entre arranques.
#
#   sudo ./crear-usb.sh brisa-0.1-amd64.iso /dev/sdX
#
# ATENCIÓN: borra TODO el contenido del USB indicado.
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
    echo "Ejecútalo como root: sudo $0 <fichero.iso> <dispositivo>" >&2; exit 1
fi
if [ $# -ne 2 ]; then
    echo "Uso: sudo $0 <fichero.iso> <dispositivo>   (por ejemplo /dev/sdb)" >&2
    echo; echo "Discos extraíbles detectados:"
    lsblk -d -o NAME,SIZE,MODEL,TRAN,RM | awk 'NR==1 || $NF==1 || /usb/'
    exit 1
fi

ISO="$1"
DISCO="$2"

for programa in lsblk dd sgdisk mkfs.ext4 partprobe; do
    if ! command -v "$programa" >/dev/null; then
        echo "Falta el programa '$programa'. Instálalo con: sudo apt install gdisk parted e2fsprogs" >&2
        exit 1
    fi
done

[ -f "$ISO" ] || { echo "No existe la ISO: $ISO" >&2; exit 1; }
[ -b "$DISCO" ] || { echo "No es un dispositivo de bloques: $DISCO" >&2; exit 1; }
[ "$(lsblk -dno TYPE "$DISCO")" = "disk" ] || {
    echo "Indica el disco entero (por ejemplo /dev/sdb), no una partición." >&2; exit 1; }

TRANSPORTE="$(lsblk -dno TRAN "$DISCO" | xargs || true)"
EXTRAIBLE="$(lsblk -dno RM "$DISCO" | xargs || true)"
if [ "$TRANSPORTE" != "usb" ] && [ "$EXTRAIBLE" != "1" ]; then
    echo "$DISCO no parece un USB ni un disco extraíble. Por seguridad no se continúa." >&2
    exit 1
fi

# Nunca sobre el disco del que está arrancado el sistema.
DISCO_SISTEMA="$(lsblk -no PKNAME "$(findmnt -no SOURCE /)" 2>/dev/null | head -n1 || true)"
if [ -n "$DISCO_SISTEMA" ] && [ "/dev/$DISCO_SISTEMA" = "$DISCO" ]; then
    echo "$DISCO es el disco del sistema en uso. No se continúa." >&2; exit 1
fi

TAM_ISO=$(stat -c %s "$ISO")
TAM_DISCO=$(lsblk -bdno SIZE "$DISCO")
if [ "$TAM_DISCO" -lt $((TAM_ISO + 2 * 1024 * 1024 * 1024)) ]; then
    echo "El USB es demasiado pequeño: hace falta el tamaño de la ISO más 2 GB como mínimo." >&2
    exit 1
fi

echo "Se va a BORRAR por completo este dispositivo:"
lsblk -o NAME,SIZE,MODEL,TRAN,MOUNTPOINTS "$DISCO"
echo
read -r -p "Para continuar escribe BORRAR en mayúsculas: " respuesta
[ "$respuesta" = "BORRAR" ] || { echo "Cancelado."; exit 1; }

echo "Desmontando particiones..."
for particion in $(lsblk -lnpo NAME "$DISCO" | tail -n +2); do
    umount "$particion" 2>/dev/null || true
done

echo "Grabando la ISO (tarda unos minutos)..."
dd if="$ISO" of="$DISCO" bs=4M conv=fsync status=progress
sync
partprobe "$DISCO" || true
sleep 3

echo "Creando la partición de persistencia..."
sgdisk -e "$DISCO"
sgdisk -n 0:0:0 -t 0:8300 -c 0:writable "$DISCO"
partprobe "$DISCO" || true
sleep 3

PARTICION="$(lsblk -lnpo NAME "$DISCO" | tail -n1)"
if [ "$PARTICION" = "$DISCO" ] || [ ! -b "$PARTICION" ]; then
    echo "No se encontró la partición nueva. La ISO está grabada, pero sin persistencia." >&2
    exit 1
fi
mkfs.ext4 -F -L writable "$PARTICION"
sync

echo
echo "Listo. El USB arranca la distro y guarda los cambios en $PARTICION."
