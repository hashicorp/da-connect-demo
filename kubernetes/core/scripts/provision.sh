#! /bin/bash -e

sudo apt-get update
sudo apt-get install -y unzip

wget -O /tmp/vault.zip "https://releases.hashicorp.com/vault/0.11.1/vault_0.11.1_linux_amd64.zip"
cd /tmp
unzip -o ./vault.zip
sudo mv -f ./vault /usr/local/bin/

sudo tee /etc/systemd/system/vault.service > /dev/null <<"EOF"
  [Unit]
  Description = "Vault"
  
  [Service]
  KillSignal=INT
  ExecStart=/usr/local/bin/vault server -dev -dev-root-token-id=mytoken
  Restart=always
EOF

sudo systemctl enable vault.service
sudo systemctl start vault.service
