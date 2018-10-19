#! /bin/bash -e

# Add K8s config for Consul auto join

# Add K8s config
mkdir -p /home/ubuntu/.kube
echo "${kube_config}" > /home/ubuntu/.kube/config
chown -R ubuntu /home/ubuntu/.kube

systemctl restart consul
