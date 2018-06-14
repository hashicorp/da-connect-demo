#! /bin/bash

consul agent -config-file /etc/consul.d/consul.hcl -config-format hcl -client 0.0.0.0 > consul.log &
sleep 5
consul intention create -deny '*' '*'
tail -f consul.log
