#!/bin/bash
set -e

# Usar variables de entorno o valores por defecto
SSH_PORT=${DPORT:-40000}
UDPGW_PORT=${UDPGW_PORT:-7300}
MAX_CLIENTS=${MAX_CLIENTS:-250}
PACKETS_SKIP=${PACKSKIP:-1}
LISTEN_PORT=${PORT:-8080}

# Función para limpiar procesos al salir
cleanup() {
    echo "[$(date)] Shutting down services..."
    pkill -f "badvpn-udpgw" || true
    pkill -f "dropbear" || true
    exit 0
}

trap cleanup SIGTERM SIGINT

echo "[$(date)] Starting UDP Gateway on port ${UDPGW_PORT}..."
badvpn-udpgw \
    --listen-addr 127.0.0.1:${UDPGW_PORT} \
    --max-clients ${MAX_CLIENTS} \
    --max-connections-for-client 3 &

echo "[$(date)] Starting Dropbear SSH on port ${SSH_PORT}..."
dropbear \
    -R \
    -E \
    -p ${SSH_PORT} \
    -W 65535 \
    -F &

echo "[$(date)] Starting Node.js proxy on port ${LISTEN_PORT}..."
echo "[$(date)] Forwarding to ${DHOST}:${SSH_PORT}, skipping ${PACKETS_SKIP} packets"

# Ejecutar proxy y esperar a que termine
node proxy3.js \
    -dhost ${DHOST} \
    -dport ${SSH_PORT} \
    -mport ${LISTEN_PORT} \
    -skip ${PACKETS_SKIP}

# Mantener el script vivo si el proxy termina (por si acaso)
wait
