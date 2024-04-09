FROM alpine:latest

RUN apk update \
 && apk add --update nodejs npm git \
 && mkdir /collabs-ws-server \
 && cd /collabs-ws-server \
 && npm install @collabs/ws-server

CMD ["/bin/ash","-c","HOST=0.0.0.0 PORT=3001 /collabs-ws-server/node_modules/@collabs/ws-server/bin/collabs-ws-server.js"]
