#!/bin/bash
set -e

# Configuración desde variables de entorno
SSH_PORT=${SSH_PORT:-40000}
UDPGW_PORT=${UDPGW_PORT:-7300}
MAX_CLIENTS=${MAX_CLIENTS:-250}
PACKETS_SKIP=${PACKETS_SKIP:-1}

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

echo "[$(date)] Starting Node.js proxy..."
exec node src/proxy.js \
    -dhost 127.0.0.1 \
    -dport ${SSH_PORT} \
    -mport ${PORT} \
    -skip ${PACKETS_SKIP}
