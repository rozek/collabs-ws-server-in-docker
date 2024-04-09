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

You may now build your docker image using

```
  docker build -t collabs-ws-server .
```

and run it (as an automatically restarted) service with

```
  docker run -d -p 3001:3001 --restart=always -it collabs-ws-server
```

If you want your server to be accessible from outside, you may have to **add a firewall rule** for the server's port: just allow your clients (or everybody) to access the configured **TCP** port (e.g., `3001`)

## Customization ##

By default, the server uses port 3001 - but you may change that as desired: in the simplest case, just change the _first_ number of the "publish" argument in the `docker run` command to the desired port number **and update your firewall rules accordingly**

```
  docker run -d -p XXXX:3001 --restart=always -it collabs-ws-server
```

(replace `XXXX` with a port number of your choice)

## License ##

[MIT License](LICENSE.md)
