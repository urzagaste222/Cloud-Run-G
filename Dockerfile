# Multi-stage build para reducir tamaño
FROM alpine:3.19 AS builder

RUN apk add --no-cache \
    alpine-sdk \
    cmake \
    linux-headers

COPY badvpn-src/ /tmp/badvpn-src

WORKDIR /tmp/badvpn-src/build
RUN cmake .. \
    -DBUILD_NOTHING_BY_DEFAULT=1 \
    -DBUILD_UDPGW=1 \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5 && \
    make -j2 && \
    make install

# Imagen final
FROM alpine:3.19

RUN apk add --no-cache \
    nodejs \
    dropbear \
    tmux \
    bash \
    && rm -rf /var/cache/apk/*

# Copiar binarios compilados
COPY --from=builder /usr/local/bin/badvpn-udpgw /usr/local/bin/

# Crear usuario no privilegiado
RUN addgroup -g 1000 -S proxy && \
    adduser -S -u 1000 -G proxy -h /app -s /bin/false proxy

WORKDIR /app

# Copiar archivos con permisos correctos
COPY --chown=proxy:proxy src/ ./src/
COPY --chown=proxy:proxy scripts/entrypoint.sh ./entrypoint.sh
RUN chmod +x ./entrypoint.sh

# Configuración por defecto
ENV PORT=8080 \
    SSH_PORT=40000 \
    UDPGW_PORT=7300 \
    MAX_CLIENTS=250 \
    PACKETS_SKIP=1

EXPOSE ${PORT}

USER proxy

CMD ["./entrypoint.sh"]
