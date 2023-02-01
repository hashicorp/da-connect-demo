#! /bin/bash -e
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0


# Add K8s config for consul auto join
mkdir -p /home/ubuntu/.kube
echo "${kube_config}" > /home/ubuntu/.kube/config
chown -R ubuntu /home/ubuntu/.kube
