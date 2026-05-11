#!/bin/bash
# Copyright IBM Corp. 2018, 2026

set -e

nohup sh -c "consul agent -config-file /etc/consul.d/consul.hcl -config-format hcl" > /dev/null 2>&1 &
