# Multi-stage build - respeta la estructura existente de badvpn-src
FROM alpine:3.19 AS builder

RUN apk add --no-cache \
    alpine-sdk \
    cmake \
    linux-headers

# Copiar todo el directorio badvpn-src con su estructura original
COPY badvpn-src/ /tmp/badvpn-src/

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

# Copiar binario compilado de badvpn
COPY --from=builder /usr/local/bin/badvpn-udpgw /usr/local/bin/

# Crear usuario no privilegiado
RUN addgroup -g 1000 -S proxy && \
    adduser -S -u 1000 -G proxy -h /app -s /bin/false proxy

WORKDIR /app

# Copiar archivos (manteniendo los nombres originales)
COPY proxy3.js ./
COPY run.sh ./
RUN chmod +x run.sh

# Eliminar código fuente (no necesario en imagen final)
RUN rm -rf /tmp/badvpn-src

# Configuración por defecto
ENV PORT=8080 \
    DHOST=127.0.0.1 \
    DPORT=40000 \
    PACKSKIP=1

EXPOSE ${PORT}

USER proxy

CMD ["./run.sh"]
