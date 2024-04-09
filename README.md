# collabs-ws-server-in-docker #

instructions for running a Collabs WebSocket Server in a Docker Container

[Collabs](https://collabs.readthedocs.io/) "is a library for collaborative data structures (CRDTs)" including a few "providers" for data persistence and synchronization over a network.

One such network provider is the [WebSocketNetworkServer](https://collabs.readthedocs.io/en/latest/api/ws-server/classes/WebSocketNetworkServer.html).

This repository tells you how to run such a server within a [Docker](https://www.docker.com/) container - independent of any other processes on your computer.

## Instructions ##

In order to build and run Docker images you must have Docker installed - for most people, installing the [Docker Desktop](https://www.docker.com/products/docker-desktop/) is the best way to do so.

Once done, create a folder for your Dockerfile and navigate into that folder, e.g.,

```
  mkdir /collabs-ws-server
  cd /collabs-ws-server
```

Now, either copy the Dockerfile from this repository into that folder or create it as follows:

```
  cat > /collabs-ws-server/Dockerfile <<'EOF'
FROM alpine:latest

RUN apk update \
 && apk add --update nodejs npm git \
 && mkdir /collabs-ws-server \
 && cd /collabs-ws-server \
 && npm install @collabs/ws-server

CMD ["/bin/ash","-c","HOST=0.0.0.0 PORT=3001 /collabs-ws-server/node_modules/@collabs/ws-server/bin/collabs-ws-server.js"]
EOF
```

You may then build your docker image using

```
  docker build -t collabs-ws-server .
```

and run it (as an automatically restarted) service with

```
  docker run -d -p 3001:3001 --restart=always -it collabs-ws-server
```

If you want your server to be accessible from outside, you may have to **add a firewall rule** for the server's port: just allow your clients (or everybody) to access the configured **TCP** port (e.g., `3001`)

## Customization ##

By default, the server uses port `3001` - but you may modify that as desired: in the simplest case, just change the _first_ number of the "publish" argument in the `docker run` command to the desired port number **and update your firewall rules accordingly**

```
  docker run -d -p XXXX:3001 --restart=always -it collabs-ws-server
```

(replace `XXXX` with a port number of your choice)

## Adding Support for WSS ##

For the time being, the original collabs-ws-server does not support TLS (i.e., HTTPS and WSS). Modern browsers, however, often require transport layer security and valid server certificates in order to communicate with external servers.

If you need a TLS-enabled WebSocket server, just follow the instructions below (rather than those shown above)

At first, create a private key for your server and obtain a signed certificate for it. Unless your server is publically accessible and has an "official" certificate (e.g., issued by [Let's Encrypt](https://letsencrypt.org/)), you will have to setup your own small "certificate authority" (CA) and let any system, that attempts to connect to your server, trust this CA. You may then use it to generate the required certificate.

**Fortunately, doing so is much simpler than you may expect**, just follow the instructions on [deliciousbrains.com](https://deliciousbrains.com/ssl-certificate-authority-for-local-https-development/)

In the end, you should have two two files, namely

  * `./SSS.key` with your server's private key and
  * `./SSS.crt` with a signed certificate for your server

where `SSS` stands for the name of your server (just an arbitrary string of your choice)

Place these files in a folder (e.g., `/cert`) and remember that folder's path.

Then create a folder for your Dockerfile and navigate into that folder, e.g.,

```
  mkdir /collabs-ws-server
  cd /collabs-ws-server
```

In this folder, create the source code for a WSS-enabled server:

```
  cat > ./collabs-ws-server.js <<'EOF'
#!/usr/bin/env node

const fs    = require('fs')
const path  = require('path')
const http  = require('http')
const https = require('https')
const { WebSocketServer } = require("ws")
const {
  WebSocketNetworkServer,
} = require("../build/commonjs/src/web_socket_network_server")

const host       = process.env.HOST || "localhost"
const port       = process.env.PORT || 3001
const CERTPrefix = process.env.CERT || ''

console.clear()

let KeyFilePath, CERTFilePath
if (CERTPrefix !== '') {
  KeyFilePath = CERTPrefix + '.key'
  if (! fs.existsSync(KeyFilePath)) {
    console.error('no key file at "' + KeyFilePath + '"')
    process.exit(1)
  }

  CERTFilePath = CERTPrefix + '.crt'
  if (! fs.existsSync(CERTFilePath)) {
    console.error('no cert file at "' + CERTFilePath + '"')
    process.exit(1)
  }
}

let server
if (CERTPrefix === '') {
  server = http.createServer((request, response) => {
    response.writeHead(200, { 'Content-Type': 'text/plain' })
    response.end('collabs-ws-server')
  })
} else {
  server = https.createServer({
    key:  fs.readFileSync(KeyFilePath),
    cert: fs.readFileSync(CERTFilePath)
  }, (request, response) => {
    response.writeHead(200, { 'Content-Type': 'text/plain' })
    response.end('collabs-ws-server')
  })
}

const wss = new WebSocketServer({ server })
new WebSocketNetworkServer(wss)

server.listen(port, host, () => {
  if (CERTPrefix === '') {
    console.log(`collabs-ws-server running at http://${host}:${port}/`)
  } else {
    console.log(`collabs-ws-server running at https://${host}:${port}/`)
  }
})
EOF
```

Now, create a new Dockerfile as follows:

```
  cat > /collabs-ws-server/Dockerfile <<'EOF'
FROM alpine:latest

RUN apk update \
 && apk add --update nodejs npm git \
 && mkdir /collabs-ws-server \
 && cd /collabs-ws-server \
 && npm install @collabs/ws-server
 
COPY ./collabs-ws-server.js /collabs-ws-server/node_modules/@collabs/ws-server/bin
RUN chmod a+x /collabs-ws-server/node_modules/@collabs/ws-server/bin/collabs-ws-server.js

CMD ["/bin/ash","-c","CERT=/cert/CCC HOST=0.0.0.0 PORT=3001 /collabs-ws-server/node_modules/@collabs/ws-server/bin/collabs-ws-server.js"]
EOF
```

where `SSS` stands for the name of your server as explained before.

You may then build your docker image using

```
  docker build -t collabs-ws-server .
```

and run it (as an automatically restarted) service with

```
  docker run -d -v /cert:/cert -v .:/src -p 3001:3001 --restart=always -it collabs-ws-server
```

If you want your server to be accessible from outside, you may have to **add a firewall rule** for the server's port: just allow your clients (or everybody) to access the configured **TCP** port (e.g., `3001`)

## Customization ##

By default, the server expects both its private key and the signed certificate in folder `/cert` and uses port `3001` - but you may modify both settings as desired: in the simplest case, just change the `docker run` command and replace

* the _first_ path of the `volume` argument with the path to your certificate folder and
* the _first_ number of the "publish" argument to the desired port number **and update your firewall rules accordingly**

```
  docker run -d -v CCCC:/cert -p XXXX:3001 --restart=always -it collabs-ws-server
```

(replace `CCCC` with a folder path and `XXXX` with a port number of your choice)

## License ##

[MIT License](LICENSE.md)
