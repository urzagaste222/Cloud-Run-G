const crypto = require('crypto');
const net = require('net');

// Configuración desde variables de entorno o argumentos
const config = {
    destHost: process.env.DHOST || '127.0.0.1',
    destPort: parseInt(process.env.DPORT) || 40000,
    listenPort: parseInt(process.env.PORT) || 8080,
    packetsToSkip: parseInt(process.env.PACKSKIP) || 1,
    enableGC: process.env.ENABLE_GC === 'true' || false
};

// Parsear argumentos de línea de comandos
process.argv.slice(2).forEach((arg, i) => {
    switch(arg) {
        case '-dhost': config.destHost = process.argv[i+3]; break;
        case '-dport': config.destPort = parseInt(process.argv[i+3]); break;
        case '-mport': config.listenPort = parseInt(process.argv[i+3]); break;
        case '-skip': config.packetsToSkip = parseInt(process.argv[i+3]); break;
    }
});

// GC opcional para producción
if (config.enableGC && global.gc) {
    setInterval(() => global.gc(), 10000);
    console.log('[INFO] Garbage collector enabled');
}

const server = net.createServer();

server.on('connection', (clientSocket) => {
    let packetCount = 0;
    const clientAddr = `${clientSocket.remoteAddress}:${clientSocket.remotePort}`;
    
    // Enviar respuesta "WebSocket upgrade" falsa
    const wsResponse = [
        'HTTP/1.1 101 Switching Protocols',
        'Connection: Upgrade',
        `Date: ${new Date().toUTCString()}`,
        `Sec-WebSocket-Accept: ${crypto.randomBytes(20).toString('base64')}`,
        'Upgrade: websocket',
        'Server: proxy/1.0',
        '',
        ''
    ].join('\r\n');
    
    clientSocket.write(wsResponse);
    console.log(`[INFO] Connection from ${clientAddr}`);

    // Conectar al servicio destino (Dropbear SSH)
    const destSocket = net.createConnection({
        host: config.destHost,
        port: config.destPort
    });

    // Manejar datos del cliente
    clientSocket.on('data', (data) => {
        if (packetCount < config.packetsToSkip) {
            packetCount++;
        } else if (packetCount === config.packetsToSkip) {
            destSocket.write(data);
            packetCount++;
        }
        // Limitar para evitar desbordamiento
        if (packetCount > config.packetsToSkip) {
            packetCount = config.packetsToSkip;
        }
    });

    // Manejar datos del destino
    destSocket.on('data', (data) => {
        clientSocket.write(data);
    });

    // Manejo de errores
    clientSocket.on('error', (err) => {
        console.error(`[ERROR] Client error ${clientAddr}: ${err.message}`);
        destSocket.destroy();
    });

    destSocket.on('error', (err) => {
        console.error(`[ERROR] Destination error: ${err.message}`);
        clientSocket.destroy();
    });

    clientSocket.on('close', () => {
        console.log(`[INFO] Connection closed ${clientAddr}`);
        destSocket.destroy();
    });
});

server.listen(config.listenPort, () => {
    console.log(`[INFO] Proxy listening on port ${config.listenPort}`);
    console.log(`[INFO] Forwarding to ${config.destHost}:${config.destPort}`);
    console.log(`[INFO] Skipping first ${config.packetsToSkip} packets`);
});
