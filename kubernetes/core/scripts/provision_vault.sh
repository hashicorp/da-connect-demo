#! /bin/bash -e

apt-get update
apt-get install -y unzip jq apt-transport-https
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
touch /etc/apt/sources.list.d/kubernetes.list 
echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubectl

# Add K8s config for Consul auto join
mkdir -p /root/.kube
echo "${kube_config}" > /root/.kube/config

# Install Vault
wget -O /tmp/vault.zip "https://releases.hashicorp.com/vault/${vault_version}/vault_${vault_version}_linux_amd64.zip"
cd /tmp
unzip -o ./vault.zip
mv -f ./vault /usr/local/bin/

tee /etc/systemd/system/vault.service > /dev/null <<"EOF"
  [Unit]
  Description = "Vault"
  
  [Service]
  KillSignal=INT
  ExecStart=/usr/local/bin/vault server -dev -dev-root-token-id=mytoken -dev-listen-address=0.0.0.0:8200
  Restart=always
EOF

systemctl enable vault.service
systemctl start vault.service

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
  ExecStart=/usr/local/bin/consul agent -retry-join 'provider=k8s label_selector="app=consul,component=server"' -data-dir=/mnt/consul.d/data -config-dir=/mnt/consul.d
  Restart=always
EOF

# Register Vault in Consul
tee /mnt/consul.d/vault.hcl > /dev/null <<"EOF"
service {
  name = "vault"
  port = 8200
  check {
    id = "vault-check"
    name = "Vault Health Check"
    http = "http://${vault_listen_address}/v1/sys/health"
    method = "GET"
    interval = "10s"
    timeout = "1s"
  }
}
EOF

systemctl enable consul.service
systemctl start consul.service
