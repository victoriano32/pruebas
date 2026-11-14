#!/bin/bash
# Se ejecuta DENTRO del chroot: instala los paquetes y configura la distro.
set -euo pipefail
source /construccion/config/distro.conf

export DEBIAN_FRONTEND=noninteractive
export LC_ALL=C
APT="apt-get -y -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold"

aviso() { echo "AVISO: $*" >&2; echo "$*" >> /construccion/avisos.txt; }
paso()  { echo; echo "----- $* -----"; }

paso "Ajustes iniciales"
echo "$EQUIPO" > /etc/hostname
cat > /etc/hosts <<FIN
127.0.0.1   localhost
127.0.1.1   $EQUIPO
::1         localhost ip6-localhost ip6-loopback
ff02::1     ip6-allnodes
ff02::2     ip6-allrouters
FIN

rm -f /etc/apt/sources.list
cat > /etc/apt/sources.list.d/ubuntu.sources <<FIN
Types: deb
URIs: $REPLICA
Suites: $BASE $BASE-updates $BASE-backports
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

Types: deb
URIs: http://security.ubuntu.com/ubuntu/
Suites: $BASE-security
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
FIN

# Sin Snap: las aplicaciones llegan por .deb y por Flatpak.
cat > /etc/apt/preferences.d/sin-snap <<FIN
Package: snapd
Pin: release a=*
Pin-Priority: -10
FIN

# Que ningún servicio intente arrancar durante la instalación.
cat > /usr/sbin/policy-rc.d <<FIN
#!/bin/sh
exit 101
FIN
chmod +x /usr/sbin/policy-rc.d

apt-get update
$APT install systemd-sysv dbus locales tzdata ca-certificates wget gnupg
dbus-uuidgen > /etc/machine-id
mkdir -p /var/lib/dbus
ln -fs /etc/machine-id /var/lib/dbus/machine-id

paso "Idioma, teclado y zona horaria"
sed -i "s/^# *\(${IDIOMA} \)/\1/; s/^# *\(en_US.UTF-8 \)/\1/" /etc/locale.gen
grep -q "^${IDIOMA} " /etc/locale.gen || echo "${IDIOMA} UTF-8" >> /etc/locale.gen
grep -q "^en_US.UTF-8 " /etc/locale.gen || echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
cat > /etc/default/locale <<FIN
LANG=$IDIOMA
LANGUAGE=${IDIOMA%%_*}:en
FIN
ln -sf "/usr/share/zoneinfo/$ZONA_HORARIA" /etc/localtime
echo "$ZONA_HORARIA" > /etc/timezone
cat > /etc/default/keyboard <<FIN
XKBMODEL="pc105"
XKBLAYOUT="$TECLADO"
XKBVARIANT=""
XKBOPTIONS=""
BACKSPACE="guess"
FIN

paso "Actualizar el sistema base"
$APT dist-upgrade

paso "Paquetes"
esenciales=()
opcionales=()
while IFS= read -r linea; do
    linea="${linea%%#*}"
    linea="$(echo "$linea" | xargs)"
    [ -z "$linea" ] && continue
    if [ "${linea:0:1}" = "!" ]; then
        esenciales+=("${linea:1}")
    else
        # Sin tubería: con "pipefail", grep -q corta a apt-cache y la comprobación falla al azar.
        politica="$(apt-cache policy "$linea" 2>/dev/null || true)"
        if grep -q 'Candidate: [^(]' <<<"$politica"; then
            opcionales+=("$linea")
        else
            aviso "paquete no disponible, se omite: $linea"
        fi
    fi
done < /construccion/config/paquetes.list

echo "Imprescindibles: ${esenciales[*]}"
$APT install "${esenciales[@]}"

echo "Opcionales: ${opcionales[*]}"
if ! $APT install "${opcionales[@]}"; then
    aviso "la instalación conjunta de opcionales falló; se instalan uno a uno"
    for p in "${opcionales[@]}"; do
        $APT install "$p" || aviso "no se pudo instalar: $p"
    done
fi

paso "Navegador (Firefox desde el repositorio de Mozilla, sin Snap)"
if install -d -m 0755 /etc/apt/keyrings \
   && wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O /etc/apt/keyrings/packages.mozilla.org.asc; then
    echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" \
        > /etc/apt/sources.list.d/mozilla.list
    cat > /etc/apt/preferences.d/mozilla <<FIN
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000
FIN
    apt-get update
    if ! $APT install firefox firefox-l10n-es-es; then
        aviso "no se pudo instalar Firefox; se instala Falkon"
        rm -f /etc/apt/sources.list.d/mozilla.list /etc/apt/preferences.d/mozilla
        apt-get update
        $APT install falkon || aviso "tampoco se pudo instalar Falkon: la ISO queda sin navegador"
    fi
else
    aviso "no se pudo descargar la clave de Mozilla; se instala Falkon"
    $APT install falkon || aviso "no se pudo instalar Falkon: la ISO queda sin navegador"
fi

paso "Paquetes .deb propios (carpeta debs/)"
if compgen -G "/construccion/debs/*.deb" >/dev/null; then
    $APT install /construccion/debs/*.deb || aviso "algún .deb propio no se pudo instalar"
else
    echo "No hay .deb propios."
fi

paso "Packs de iconos adicionales (Tela y Fluent)"
instalar_iconos() {
    local nombre="$1" url="$2"; shift 2
    local tmp; tmp="$(mktemp -d)"
    if git clone --depth 1 "$url" "$tmp/src" >/dev/null 2>&1 \
       && ( cd "$tmp/src" && bash ./install.sh -d /usr/share/icons "$@" >/dev/null 2>&1 ); then
        echo "Instalado: $nombre"
    else
        aviso "no se pudo instalar el pack de iconos $nombre"
    fi
    rm -rf "$tmp"
}
if command -v git >/dev/null; then
    instalar_iconos "Tela" "https://github.com/vinceliuice/Tela-icon-theme.git" standard purple blue green orange
    instalar_iconos "Fluent" "https://github.com/vinceliuice/Fluent-icon-theme.git"
else
    aviso "git no está instalado: sin packs Tela ni Fluent"
fi

paso "Tienda Flathub"
if command -v flatpak >/dev/null; then
    flatpak remote-add --system --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo \
        || aviso "no se pudo añadir Flathub (se puede añadir después desde Discover)"
fi

paso "Ficheros propios de la distro"
# Sin conservar el propietario: todo debe quedar como root, no como el usuario que compila.
chmod -R go-w /construccion/overlay
cp -r --preserve=mode,timestamps,links /construccion/overlay/. /
chmod 755 /usr/bin/brisa-personalizar
find /construccion/overlay -mindepth 1 -type d | sed 's#^/construccion/overlay##' | while read -r d; do
    chmod 755 "$d"
done

# Disposición de serie del tema global: el panel tipo dock + el fondo de la distro
mkdir -p /usr/share/plasma/look-and-feel/org.brisa.desktop/contents/layouts
sed "s/@ICONO_MENU@/$ICONO_MENU/g" \
    /usr/share/brisa/disposiciones/dock.js /usr/share/brisa/disposiciones/_escritorio.js \
    > /usr/share/plasma/look-and-feel/org.brisa.desktop/contents/layouts/org.kde.plasma.desktop-layout.js

# Si Papirus no se instaló, el tema de iconos de serie vuelve a Breeze
if [ ! -d /usr/share/icons/Papirus ]; then
    aviso "Papirus no está instalado: se usa Breeze como tema de iconos de serie"
    sed -i 's/^Theme=Papirus.*/Theme=breeze/' /etc/xdg/kdeglobals \
        /usr/share/plasma/look-and-feel/org.brisa.desktop/contents/defaults
fi
gtk-update-icon-cache -f -t /usr/share/icons/hicolor 2>/dev/null || true

paso "Marca de la distro"
if [ -f /usr/lib/os-release ]; then
    sed -i "s/^NAME=.*/NAME=\"$NOMBRE\"/; s/^PRETTY_NAME=.*/PRETTY_NAME=\"$NOMBRE $VERSION (Ubuntu $BASE_VERSION)\"/" /usr/lib/os-release
fi
if [ -f /etc/lsb-release ]; then
    sed -i "s/^DISTRIB_DESCRIPTION=.*/DISTRIB_DESCRIPTION=\"$NOMBRE $VERSION\"/" /etc/lsb-release
fi
echo "$NOMBRE $VERSION \\n \\l" > /etc/issue

paso "Sesión en vivo"
cat > /etc/casper.conf <<FIN
export USERNAME="$USUARIO_VIVO"
export USERFULLNAME="Usuario de $NOMBRE"
export HOST="$EQUIPO"
export BUILD_SYSTEM="Ubuntu"
export FLAVOUR="$NOMBRE"
FIN
mkdir -p /etc/sddm.conf.d
cat > /etc/sddm.conf.d/20-sesion-en-vivo.conf <<FIN
[Autologin]
User=$USUARIO_VIVO
Session=plasma.desktop
FIN

paso "Red"
mkdir -p /etc/NetworkManager/conf.d
touch /etc/NetworkManager/conf.d/10-globally-managed-devices.conf
if [ -d /etc/netplan ]; then
    cat > /etc/netplan/01-network-manager-all.yaml <<FIN
network:
  version: 2
  renderer: NetworkManager
FIN
    chmod 600 /etc/netplan/01-network-manager-all.yaml
fi

paso "Regenerar el initramfs (con casper)"
update-initramfs -u -k all

echo
echo "Configuración terminada."
if [ -s /construccion/avisos.txt ]; then
    echo "Avisos acumulados:"
    cat /construccion/avisos.txt
fi
