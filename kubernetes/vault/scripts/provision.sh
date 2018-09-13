#! /bin/bash -e

sudo apt-get update
sudo apt-get install -y unzip

wget -O /tmp/vault.zip "https://releases.hashicorp.com/vault/0.11.1/vault_0.11.1_linux_amd64.zip"
cd /tmp
unzip -o ./vault.zip
sudo mv -f ./vault /usr/local/bin/

sudo mkdir -p /etc/vault.d
sudo chmod 755 /etc/vault.d
sudo mv -f /tmp/cert.pem /etc/vault.d/
sudo mv -f /tmp/key.pem /etc/vault.d/

sudo tee /etc/systemd/system/vault.service > /dev/null <<"EOF"
  [Unit]
  Description = "Vault"
  
  [Service]
  KillSignal=INT
  ExecStart=/usr/local/bin/vault server -dev -dev-root-token-id=mytoken -client-cert=/etc/vault.d/cert.pem -client-key=/etc/vault.d/key.pem
  Restart=always
EOF

sudo systemctl enable vault.service
sudo systemctl start vault.service
