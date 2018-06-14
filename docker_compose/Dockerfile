FROM ubuntu

RUN apt-get update; apt-get install -y socat netcat curl net-tools jq postgresql-client iptables ngrep

COPY ./consul /usr/local/bin/consul

EXPOSE 5432
