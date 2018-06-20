#!/bin/bash
set -e

nohup sh -c "consul agent -config-file /etc/consul.d/consul.hcl -config-format hcl" > /dev/null 2>&1 &
