#!/bin/bash
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

set -e

nohup sh -c "consul agent -config-file /etc/consul.d/consul.hcl -config-format hcl" > /dev/null 2>&1 &
