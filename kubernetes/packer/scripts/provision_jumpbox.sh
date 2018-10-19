#! /bin/bash -e
apt-get update
apt-get install -y unzip jq apt-transport-https dnsmasq redis-tools postgresql-client

# Install KubeCtl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
touch /etc/apt/sources.list.d/kubernetes.list 
echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubectl

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

systemctl enable consul.service
sudo systemctl add-wants multi-user.target consul.service

# Configure DNSMasq
tee /etc/dnsmasq.d/10_consul > /dev/null <<"EOF"
no-resolv
server=/consul/127.0.0.1#8600
server=8.8.8.8
EOF

# We need the auto auto to run as user ubuntu otherwise the file containing the 
# vault token will not be readable without sudo
tee /etc/systemd/system/vault-auto-auth.service > /dev/null <<"EOF"
  [Unit]
  Description = "Vault Auto Auth"
  
  [Service]
  User=ubuntu
  KillSignal=INT
  ExecStart=/usr/local/bin/vault agent -address http://vault.service.consul:8200 -config /home/ubuntu/.vault-auto-auth
  Restart=always
EOF

systemctl enable vault-auto-auth.service
sudo systemctl add-wants multi-user.target vault-auto-auth.service

