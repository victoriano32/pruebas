#!/usr/bin/env bash
# Inserta el servidor de puente/servidor.conf en el código antes de compilar.
set -euo pipefail
cd "$(dirname "$0")/.."
# shellcheck disable=SC1091
source <(tr -d '\r' < puente/servidor.conf | grep -E '^(SERVIDOR|CLAVE)=')
SERVIDOR="${SERVIDOR:-}"; CLAVE="${CLAVE:-}"
CFG=libs/hbb_common/src/config.rs
if [[ -z "$SERVIDOR" ]]; then
  echo "Sin servidor propio: se usarán los servidores públicos."
  exit 0
fi
sed -i -E "s|^pub const RENDEZVOUS_SERVERS: &\[&str\] = &\[.*\];|pub const RENDEZVOUS_SERVERS: \&[\&str] = \&[\"${SERVIDOR}\"];|" "$CFG"
if [[ -n "$CLAVE" ]]; then
  sed -i -E "s|^pub const RS_PUB_KEY: &str = \".*\";|pub const RS_PUB_KEY: \&str = \"${CLAVE}\";|" "$CFG"
fi
grep -nE '^pub const (RENDEZVOUS_SERVERS|RS_PUB_KEY)' "$CFG"
