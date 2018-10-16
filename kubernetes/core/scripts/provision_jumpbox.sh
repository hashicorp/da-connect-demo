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

# Enable Certmanager
cat <<EOF | KUBECONFIG=/home/ubuntu/.kube/config kubectl apply -f -
---
apiVersion: certmanager.k8s.io/v1alpha1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: ${letsencrypt_email} 
    privateKeySecretRef:
      name: letsencrypt-staging
    http01: {}

---
apiVersion: certmanager.k8s.io/v1alpha1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v01.api.letsencrypt.org/directory
    email: ${letsencrypt_email}
    privateKeySecretRef:
      name: letsencrypt-prod
    http01: {}
EOF

# Configure DNSMasq
tee /etc/dnsmasq.d/10_consul > /dev/null <<"EOF"
no-resolv
server=/consul/127.0.0.1#8600
server=8.8.8.8
EOF

systemctl restart dnsmasq

# Configure Vault Auto Auth
tee /home/ubuntu/.vault-auto-auth > /dev/null <<"EOF"
    "auto_auth" {
      method "azure" {
        config {
          role = "jumpbox-role"
					resource = "https://management.azure.com/"
        }
      }

      sink "file" {
        config {
          path = "/home/ubuntu/.vault_token"
        }
      }
    }
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
systemctl start vault-auto-auth.service

# Update profile
echo "export KUBECONFIG=/home/ubuntu/.kube/config" >> /home/ubuntu/.profile
echo "export VAULT_ADDR=http://vault.service.consul:8200" >> /home/ubuntu/.profile
echo 'export VAULT_TOKEN=$(cat /home/ubuntu/.vault_token)' >> /home/ubuntu/.profile
