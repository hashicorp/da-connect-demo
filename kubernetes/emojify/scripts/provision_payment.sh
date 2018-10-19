#! /bin/bash -e

# Add K8s config for consul auto join
mkdir -p /home/ubuntu/.kube
echo "${kube_config}" > /home/ubuntu/.kube/config
chown -R ubuntu /home/ubuntu/.kube
