# Cloud-Run-G

# Proxy Service with UDP Gateway + SSH

Servicio de proxy que combina:
- **badvpn-udpgw**: Gateway UDP sobre TCP
- **Dropbear**: Servidor SSH ligero  
- **Node.js Proxy**: Camuflaje de tráfico con handshake WebSocket falso

## Configuración

| Variable | Default | Descripción |
|----------|---------|-------------|
| `PORT` | 8080 | Puerto del proxy Node.js |
| `SSH_PORT` | 40000 | Puerto interno de Dropbear |
| `UDPGW_PORT` | 7300 | Puerto interno de UDP gateway |
| `MAX_CLIENTS` | 250 | Máximo clientes UDP gateway |
| `PACKETS_SKIP` | 1 | Paquetes a saltar en proxy |

## Despliegue en Cloud Run

```bash
gcloud run deploy proxy-service \
    --source . \
    --platform managed \
    --region us-central1 \
    --allow-unauthenticated \
    --port 8080
