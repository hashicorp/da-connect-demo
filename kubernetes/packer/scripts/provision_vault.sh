#! /bin/bash -e

apt-get update
apt-get install -y unzip jq apt-transport-https

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
sudo systemctl add-wants multi-user.target vault.service

# Install Consul
wget -O /tmp/consul.zip "https://releases.hashicorp.com/consul/${consul_version}/consul_${consul_version}_linux_amd64.zip"
cd /tmp
unzip -o ./consul.zip
mv -f ./consul /usr/local/bin/

# Create Consul data folder
mkdir -p /etc/consul.d
mkdir -p /etc/consul.d/data

tee /etc/systemd/system/consul.service > /dev/null <<"EOF"
  [Unit]
  Description = "Consul"
  
  [Service]
  KillSignal=INT
  ExecStart=/usr/local/bin/consul agent -retry-join 'provider=k8s label_selector="app=consul,component=server" kubeconfig=/home/ubuntu/.kube/config' -data-dir=/etc/consul.d/data -config-dir=/etc/consul.d
  Restart=always
EOF

# Register Vault in Consul
tee /etc/consul.d/vault.hcl > /dev/null <<"EOF"
service {
  name = "Vault"
  port = 8200
  check {
    id = "vault-check"
    name = "Vault Health Check"
    http = "http://localhost:8200/v1/sys/health"
    method = "GET"
    interval = "10s"
    timeout = "1s"
  }
}
EOF

systemctl enable consul.service
sudo systemctl add-wants multi-user.target consul.service
