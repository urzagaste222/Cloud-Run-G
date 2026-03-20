# Multi-stage build - sin necesidad de tener badvpn en el repo
FROM alpine:3.19 AS builder

RUN apk add --no-cache \
    alpine-sdk \
    cmake \
    linux-headers \
    git

# Clonar badvpn oficial
RUN git clone https://github.com/ambrop72/badvpn.git /tmp/badvpn

WORKDIR /tmp/badvpn/build
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

COPY --from=builder /usr/local/bin/badvpn-udpgw /usr/local/bin/

RUN addgroup -g 1000 -S proxy && \
    adduser -S -u 1000 -G proxy -h /app -s /bin/false proxy

WORKDIR /app

COPY proxy3.js ./
COPY run.sh ./
RUN chmod +x run.sh

ENV PORT=8080 \
    DHOST=127.0.0.1 \
    DPORT=40000 \
    PACKSKIP=1

EXPOSE ${PORT}

USER proxy

CMD ["./run.sh"]
