#!/bin/bash
# Se ejecuta DENTRO del chroot al final: deja el sistema limpio antes de comprimirlo.
set -uo pipefail
export DEBIAN_FRONTEND=noninteractive

apt-get -y autoremove --purge
apt-get clean
rm -rf /var/lib/apt/lists/*
rm -f /usr/sbin/policy-rc.d
: > /etc/machine-id
rm -f /var/lib/dbus/machine-id
rm -rf /tmp/* /var/tmp/* /root/.bash_history /root/.cache /root/.wget-hsts
find /var/log -type f -exec truncate -s 0 {} + 2>/dev/null
exit 0
