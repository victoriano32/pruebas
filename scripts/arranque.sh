#!/bin/bash
# Se ejecuta DENTRO del chroot: genera el menú de arranque y los cargadores para BIOS y UEFI.
set -euo pipefail
source /construccion/config/distro.conf

D=/construccion/arranque
rm -rf "$D"; mkdir -p "$D"; cd "$D"

COMUN="boot=casper locale=$IDIOMA keyboard-configuration/layoutcode=$TECLADO quiet splash"

cat > grub.cfg <<FIN
search --set=root --file /brisa-live

if [ "\$grub_platform" = "efi" ]; then
    insmod all_video
fi

set default="0"
set timeout=8

menuentry "$NOMBRE $VERSION (guarda los cambios si el USB tiene persistencia)" {
    linux /casper/vmlinuz $COMUN persistent ---
    initrd /casper/initrd
}
menuentry "$NOMBRE $VERSION sin guardar cambios" {
    linux /casper/vmlinuz $COMUN nopersistent ---
    initrd /casper/initrd
}
menuentry "$NOMBRE $VERSION - modo gráfico seguro" {
    linux /casper/vmlinuz $COMUN persistent nomodeset ---
    initrd /casper/initrd
}
menuentry "$NOMBRE $VERSION - cargar en memoria RAM (sin persistencia)" {
    linux /casper/vmlinuz $COMUN nopersistent toram ---
    initrd /casper/initrd
}
FIN

# --- UEFI ---
SHIM=""
for candidato in /usr/lib/shim/shimx64.efi.signed.latest /usr/lib/shim/shimx64.efi.signed.previous \
                 /usr/lib/shim/shimx64.efi.signed /usr/lib/shim/shimx64.efi.dualsigned; do
    if [ -f "$candidato" ]; then SHIM="$candidato"; break; fi
done
GRUB_FIRMADO=/usr/lib/grub/x86_64-efi-signed/grubx64.efi.signed

if [ -n "$SHIM" ] && [ -f "$GRUB_FIRMADO" ] && [ -f /usr/lib/shim/mmx64.efi ]; then
    echo "UEFI: cargadores firmados (compatible con Secure Boot)"
    cp "$SHIM" bootx64.efi
    cp /usr/lib/shim/mmx64.efi mmx64.efi
    cp "$GRUB_FIRMADO" grubx64.efi
else
    echo "AVISO: no hay cargadores firmados; la ISO necesitará Secure Boot desactivado" >&2
    grub-mkstandalone --format=x86_64-efi --output=bootx64.efi --locales="" --fonts="" \
        "boot/grub/grub.cfg=grub.cfg"
    cp bootx64.efi grubx64.efi
    cp bootx64.efi mmx64.efi
fi

dd if=/dev/zero of=efiboot.img bs=1M count=12 status=none
mkfs.vfat -F 16 efiboot.img >/dev/null
LC_CTYPE=C mmd -i efiboot.img efi efi/ubuntu efi/boot
LC_CTYPE=C mcopy -i efiboot.img ./bootx64.efi ::efi/boot/bootx64.efi
LC_CTYPE=C mcopy -i efiboot.img ./mmx64.efi ::efi/boot/mmx64.efi
LC_CTYPE=C mcopy -i efiboot.img ./grubx64.efi ::efi/boot/grubx64.efi
LC_CTYPE=C mcopy -i efiboot.img ./grub.cfg ::efi/ubuntu/grub.cfg

# --- BIOS ---
grub-mkstandalone --format=i386-pc --output=core.img \
    --install-modules="linux16 linux normal iso9660 biosdisk memdisk search tar ls test echo part_gpt part_msdos" \
    --modules="linux16 linux normal iso9660 biosdisk search part_gpt part_msdos" \
    --locales="" --fonts="" \
    "boot/grub/grub.cfg=grub.cfg"
cat /usr/lib/grub/i386-pc/cdboot.img core.img > bios.img
rm -f core.img

ls -l "$D"
