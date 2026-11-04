#!/usr/bin/env bash
# Instala el servidor Puente en un Linux (Ubuntu/Debian/Mint) con Docker.
# Uso:  curl -fsSL <url-raw-de-este-archivo> | sudo bash     o bien   sudo bash instalar.sh
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Ejecútalo con sudo"; exit 1; }
DIR=/opt/puente-servidor
mkdir -p "$DIR" && cd "$DIR"

if ! command -v docker >/dev/null; then
  echo "== Instalando Docker"
  curl -fsSL https://get.docker.com | sh
fi

echo "== Descargando configuración"
SRC="$(cd "$(dirname "${BASH_SOURCE[0]:-.}")" && pwd)"
if [[ -f "$SRC/docker-compose.yml" ]]; then cp "$SRC/docker-compose.yml" .; else
  curl -fsSL https://raw.githubusercontent.com/victoriano32/pruebas/puente/servidor/docker-compose.yml -o docker-compose.yml
fi

echo "== Abriendo puertos en el cortafuegos (si ufw está activo)"
if command -v ufw >/dev/null && ufw status | grep -q active; then
  ufw allow 21114:21119/tcp; ufw allow 21116/udp
fi

echo "== Arrancando"
docker compose up -d
for i in {1..30}; do [[ -f data/id_ed25519.pub ]] && break; sleep 1; done

IP=$(curl -fsS https://api.ipify.org || echo "TU_IP_PUBLICA")
echo
echo "=============================================="
echo " Servidor Puente funcionando"
echo " SERVIDOR=$IP"
echo " CLAVE=$(cat data/id_ed25519.pub 2>/dev/null || echo '(aún generándose: cat /opt/puente-servidor/data/id_ed25519.pub)')"
echo "=============================================="
echo "Copia estas dos líneas en puente/servidor.conf del repositorio."
echo "Si el servidor está en casa, abre en el router: TCP 21115-21117, UDP 21116."
