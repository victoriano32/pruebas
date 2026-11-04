# Servidor propio de Puente

Tu servidor hace dos cosas: da a cada equipo su **ID** (como en AnyDesk) y, cuando no se puede conectar directamente, hace de **relé**. Casi siempre la conexión acaba siendo directa (P2P), así que el servidor gasta muy poco.

## Dónde ponerlo
- **VPS** (lo más fácil y fiable): cualquier VPS Linux con 1 CPU y 1 GB de RAM sirve (IONOS, Hetzner, Oracle Cloud gratis…).
- **En casa**: un PC o Raspberry Pi siempre encendido. Tendrás que abrir puertos en el router.

## Instalación (2 minutos)
```bash
git clone -b puente --depth 1 https://github.com/victoriano32/pruebas puente
cd puente/servidor
sudo bash instalar.sh
```
Al final te muestra dos líneas: `SERVIDOR=...` y `CLAVE=...`.

## Puertos
| Puerto | Tipo | Uso |
|---|---|---|
| 21115 | TCP | Prueba de NAT |
| 21116 | TCP y UDP | ID y perforación P2P |
| 21117 | TCP | Relé |

En un VPS abre estos puertos también en el panel de cortafuegos del proveedor.

## Conectar las apps a tu servidor
**Opción A (recomendada, automática):** pega las dos líneas en `puente/servidor.conf`, haz commit y push a la rama `puente`. GitHub recompila las tres apps ya configuradas.

**Opción B (manual):** en cada app → Ajustes → Red → Servidor de ID/Relé: pon la IP en "Servidor de ID" y la clave en "Key".

## Mantenimiento
```bash
cd /opt/puente-servidor
sudo docker compose pull && sudo docker compose up -d   # actualizar
sudo docker compose logs -f                             # ver registros
```
Guarda una copia de `/opt/puente-servidor/data/`: ahí están las claves. Si las pierdes, tendrás que recompilar con la clave nueva.
