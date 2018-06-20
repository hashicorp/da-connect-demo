#! /bin/sh

consul agent -config-file /etc/consul.d/consul.hcl -config-format hcl -client 0.0.0.0 > consul.log &
sleep 5
tail -f consul.log
