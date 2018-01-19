const http = require('http');
const port = 300;

function printHeaders(arr) {
    for (let i = 0; i < arr.length;i += 2)
        console.log('    ' + arr[i] + ': ' + arr[i+1]);
}

const requestHandler = (request, response) => {
    console.log(request.socket.remoteAddress + " " + request.method + " " + request.url);
    printHeaders(request.rawHeaders);
    printHeaders(request.rawTrailers);
    response.setHeader("Cache-Control", "only-if-cached, max-age=60");
    //response.setHeader("Content-Type", "text/html;charsert=utf-8");
    response.writeHead(200, { 'Content-Type': 'text/plain' });
    response.end('<html><body><h1>This page should be cached by the client for 60 seconds!</h1></body></html>');
}

const server = http.createServer(requestHandler);
server.on('connection', (socket) => {
    console.log(socket.remoteAddress + " connected");
    socket.on('close', (had_error) => {
        console.log(socket.remoteAddress + ' disconnected ' + ((had_error) ? 'with error' : ''));
    });
});
server.on('close', () => {
    console.log('server closed');
});

server.on('clientError', (err, socket) => {
    socket.end('HTTP/1.1 400 Bad Request\r\n\r\n');
});

server.listen(port, (err) => {
    if (err) {
        return console.log('something bad happened', err);
    }
    console.log('opened server on', server.address());
});

