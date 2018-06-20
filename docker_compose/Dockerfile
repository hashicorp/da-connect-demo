FROM alpine

RUN apk update; apk add socat netcat-openbsd curl jq postgresql-client ngrep

COPY ./consul /usr/local/bin/consul

EXPOSE 5432
