#! /bin/bash -e

apt-get update
apt-get install -y unzip jq apt-transport-https dnsmasq redis-tools postgresql-client

# Install KubeCtl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
touch /etc/apt/sources.list.d/kubernetes.list 
echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubectl

# Add K8s config
mkdir -p /home/ubuntu/.kube
echo "${kube_config}" > /home/ubuntu/.kube/config
echo "${kube_ca_cert}" > /home/ubuntu/.kube/cluster_ca_certificate.pem
chown -R ubuntu /home/ubuntu/.kube

# Install Vault
wget -O /tmp/vault.zip "https://releases.hashicorp.com/vault/${vault_version}/vault_${vault_version}_linux_amd64.zip"
cd /tmp
unzip -o ./vault.zip
mv -f ./vault /usr/local/bin/

# Install Consul
wget -O /tmp/consul.zip "https://releases.hashicorp.com/consul/${consul_version}/consul_${consul_version}_linux_amd64.zip"
cd /tmp
unzip -o ./consul.zip
mv -f ./consul /usr/local/bin/
mkdir -p /mnt/consul.d
mkdir -p /mnt/consul.d/data

tee /etc/systemd/system/consul.service > /dev/null <<"EOF"
  [Unit]
  Description = "Consul"
  
  [Service]
  KillSignal=INT
  ExecStart=/usr/local/bin/consul agent -retry-join 'provider=k8s label_selector="app=consul,component=server" kubeconfig=/home/ubuntu/.kube/config' -data-dir=/mnt/consul.d/data -config-dir=/mnt/consul.d
  Restart=always
EOF

systemctl enable consul.service
systemctl start consul.service

# Enable KubeDNS for Consul
cat <<EOF | KUBECONFIG=/home/ubuntu/.kube/config kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  labels:
    addonmanager.kubernetes.io/mode: EnsureExists
  name: kube-dns
  namespace: kube-system
data:
  stubDomains: |
    {"consul": ["$(KUBECONFIG=/home/ubuntu/.kube/config kubectl get svc consul-dns -o jsonpath='{.spec.clusterIP}')"]}
EOF

# Enable Kubernetes Service Account to access Token Review API
cat <<EOF | KUBECONFIG=/home/ubuntu/.kube/config kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: role-tokenreview-binding
  namespace: default
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:auth-delegator
subjects:
- kind: ServiceAccount
  name: vault-auth
  namespace: default
EOF


# Configure DNSMasq
tee /etc/dnsmasq.d/10_consul > /dev/null <<"EOF"
no-resolv
server=/consul/127.0.0.1#8600
server=8.8.8.8
EOF

systemctl restart dnsmasq

# Update profile
echo "export KUBECONFIG=/home/ubuntu/.kube/config" >> /home/ubuntu/.profile
echo "export VAULT_ADDR=http://vault.service.consul:8200" >> /home/ubuntu/.profile
echo "export VAULT_TOKEN=${vault_token}" >> /home/ubuntu/.profile
