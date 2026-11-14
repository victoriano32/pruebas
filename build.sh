#!/usr/bin/env bash
# Construye la ISO de la distro. Hay que ejecutarlo como root en un sistema Ubuntu/Debian/Mint:
#     sudo ./build.sh
# El resultado queda en salida/<nombre>-<versión>-amd64.iso
set -euo pipefail

AQUI="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=config/distro.conf
source "$AQUI/config/distro.conf"

TRABAJO="${TRABAJO:-$AQUI/trabajo}"
RAIZ="$TRABAJO/chroot"
IMAGEN="$TRABAJO/imagen"
SALIDA="$AQUI/salida"
NOMBRE_MIN="$(echo "$NOMBRE" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9\n' '-')"
ISO="$SALIDA/${NOMBRE_MIN}-${VERSION}-${ARQUITECTURA}.iso"

paso() { echo; echo "=============== $* ==============="; }

if [ "$(id -u)" -ne 0 ]; then
    echo "Ejecuta este script como root: sudo ./build.sh" >&2
    exit 1
fi

desmontar() {
    for punto in dev/pts dev proc sys run; do
        mountpoint -q "$RAIZ/$punto" 2>/dev/null && umount -lf "$RAIZ/$punto" || true
    done
}
trap desmontar EXIT

paso "Herramientas del equipo anfitrión"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq debootstrap squashfs-tools ubuntu-keyring rsync >/dev/null
# Un debootstrap antiguo puede no conocer la versión nueva de Ubuntu: todas usan el mismo guion.
if [ ! -e "/usr/share/debootstrap/scripts/$BASE" ]; then
    ln -s gutsy "/usr/share/debootstrap/scripts/$BASE"
fi

paso "Sistema base ($BASE)"
desmontar
rm -rf "$TRABAJO"
mkdir -p "$RAIZ" "$IMAGEN/casper" "$SALIDA"
debootstrap --arch="$ARQUITECTURA" --variant=minbase \
    --components=main,restricted,universe,multiverse \
    "$BASE" "$RAIZ" "$REPLICA"

paso "Preparar el chroot"
mount --bind /dev "$RAIZ/dev"
mount --bind /dev/pts "$RAIZ/dev/pts"
mount -t proc proc "$RAIZ/proc"
mount -t sysfs sysfs "$RAIZ/sys"
mount -t tmpfs tmpfs "$RAIZ/run"
mkdir -p "$RAIZ/run/systemd/resolve"
cp -L /etc/resolv.conf "$RAIZ/run/systemd/resolve/stub-resolv.conf" 2>/dev/null || true
rm -f "$RAIZ/etc/resolv.conf"
cp -L /etc/resolv.conf "$RAIZ/etc/resolv.conf"

mkdir -p "$RAIZ/construccion"
cp -r "$AQUI/config" "$AQUI/scripts" "$AQUI/overlay" "$RAIZ/construccion/"
mkdir -p "$RAIZ/construccion/debs"
if compgen -G "$AQUI/debs/*.deb" >/dev/null; then
    cp "$AQUI"/debs/*.deb "$RAIZ/construccion/debs/"
fi

paso "Instalar y configurar el sistema (dentro del chroot)"
chroot "$RAIZ" /usr/bin/env -i HOME=/root TERM="${TERM:-xterm}" \
    PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    /bin/bash /construccion/scripts/chroot.sh

paso "Preparar el arranque (GRUB para BIOS y UEFI)"
chroot "$RAIZ" /usr/bin/env -i HOME=/root \
    PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    /bin/bash /construccion/scripts/arranque.sh

# Núcleo e initrd
cp "$(ls -1 "$RAIZ"/boot/vmlinuz-* | sort -V | tail -n1)" "$IMAGEN/casper/vmlinuz"
cp "$(ls -1 "$RAIZ"/boot/initrd.img-* | sort -V | tail -n1)" "$IMAGEN/casper/initrd"
# Ficheros de arranque generados dentro del chroot
mkdir -p "$IMAGEN/isolinux"
cp -r "$RAIZ/construccion/arranque/." "$IMAGEN/isolinux/"

chroot "$RAIZ" dpkg-query -W --showformat='${Package} ${Version}\n' > "$IMAGEN/casper/filesystem.manifest"

paso "Limpiar el chroot"
chroot "$RAIZ" /bin/bash /construccion/scripts/limpiar.sh
desmontar
if [ -s "$RAIZ/construccion/avisos.txt" ]; then
    cp "$RAIZ/construccion/avisos.txt" "$SALIDA/avisos.txt"
else
    echo "Sin avisos." > "$SALIDA/avisos.txt"
fi
rm -rf "$RAIZ/construccion"
# Resolución de nombres: el enlace normal de Ubuntu si está systemd-resolved;
# si no, se deja sin fichero y lo crea NetworkManager.
rm -f "$RAIZ/etc/resolv.conf"
if [ -e "$RAIZ/usr/lib/systemd/systemd-resolved" ]; then
    ln -s ../run/systemd/resolve/stub-resolv.conf "$RAIZ/etc/resolv.conf"
fi

paso "Comprimir el sistema (squashfs)"
mksquashfs "$RAIZ" "$IMAGEN/casper/filesystem.squashfs" \
    -noappend -no-duplicates -no-recovery -wildcards \
    -comp zstd -Xcompression-level 17 -b 1M \
    -e "var/cache/apt/archives/*" -e "root/*" -e "root/.*" -e "tmp/*" -e "tmp/.*" -e "swapfile"
printf '%s' "$(du -sx --block-size=1 "$RAIZ" | cut -f1)" > "$IMAGEN/casper/filesystem.size"

paso "Montar la ISO"
touch "$IMAGEN/brisa-live"
mkdir -p "$IMAGEN/.disk"
echo "$NOMBRE $VERSION (basada en Ubuntu $BASE_VERSION) - $ARQUITECTURA ($(date +%Y%m%d))" > "$IMAGEN/.disk/info"
cat > "$IMAGEN/README.diskdefines" <<FIN
#define DISKNAME  $NOMBRE $VERSION
#define TYPE  binary
#define TYPEbinary  1
#define ARCH  $ARQUITECTURA
#define ARCH$ARQUITECTURA  1
#define DISKNUM  1
#define DISKNUM1  1
#define TOTALNUM  0
#define TOTALNUM0  1
FIN

# La ISO se monta con el xorriso del propio chroot para que coincida con el GRUB de la distro.
mkdir -p "$RAIZ/imagen" "$RAIZ/salida"
mount --bind "$IMAGEN" "$RAIZ/imagen"
mount --bind "$SALIDA" "$RAIZ/salida"
trap 'umount -lf "$RAIZ/imagen" "$RAIZ/salida" 2>/dev/null || true; desmontar' EXIT

chroot "$RAIZ" /bin/bash -euc '
cd /imagen
find . -type f ! -name md5sum.txt ! -path "./isolinux/*" -print0 | xargs -0 md5sum > md5sum.txt
xorriso -as mkisofs \
    -iso-level 3 -full-iso9660-filenames -J -joliet-long \
    -volid "'"$(echo "${NOMBRE}_${VERSION}" | tr -c 'A-Za-z0-9_\n' '_' | cut -c1-32)"'" \
    -output "/salida/'"$(basename "$ISO")"'" \
    -eltorito-boot isolinux/bios.img \
        -no-emul-boot -boot-load-size 4 -boot-info-table \
        --eltorito-catalog boot.catalog \
        --grub2-boot-info --grub2-mbr /usr/lib/grub/i386-pc/boot_hybrid.img \
        -partition_offset 16 --mbr-force-bootable \
    -eltorito-alt-boot \
        -no-emul-boot -e isolinux/efiboot.img \
        -append_partition 2 28732ac11ff8d211ba4b00a0c93ec93b isolinux/efiboot.img \
        -appended_part_as_gpt \
        -iso_mbr_part_type a2a0d0ebe5b9334487c068b6b72699c7 \
    -m "isolinux/efiboot.img" -m "isolinux/bios.img" \
    -e "--interval:appended_partition_2:::" \
    -exclude isolinux \
    -graft-points \
        "/EFI/boot/bootx64.efi=isolinux/bootx64.efi" \
        "/EFI/boot/grubx64.efi=isolinux/grubx64.efi" \
        "/EFI/boot/mmx64.efi=isolinux/mmx64.efi" \
        "/EFI/ubuntu/grub.cfg=isolinux/grub.cfg" \
        "/boot/grub/grub.cfg=isolinux/grub.cfg" \
        "/isolinux/bios.img=isolinux/bios.img" \
        "/isolinux/efiboot.img=isolinux/efiboot.img" \
        "."
'
umount -lf "$RAIZ/imagen" "$RAIZ/salida"
rmdir "$RAIZ/imagen" "$RAIZ/salida" 2>/dev/null || true

( cd "$SALIDA" && sha256sum "$(basename "$ISO")" > "$(basename "$ISO").sha256" )

paso "Terminado"
ls -lh "$ISO"
