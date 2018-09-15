#! /bin/bash -e

sudo apt-get update
sudo apt-get install -y unzip

wget -O /tmp/consul.zip "https://releases.hashicorp.com/consul/${consul_version}/consul_${consul_version}_linux_amd64.zip"
cd /tmp
unzip -o ./consul.zip
sudo mv -f ./consul /usr/local/bin/

sudo mkdir -p /etc/consul.d
sudo chmod 755 /etc/consul.d

sudo tee /etc/systemd/system/consul_connect.service > /dev/null <<"EOF"
  [Unit]
  Description = "Consul Connect Proxy"
  
  [Service]
  KillSignal=INT
  ExecStart=/usr/local/bin/consul connect proxy -log-level=DEBUG -service emojify-redis -http-addr localhost:8500 -register -listen ${listen_addr} -service-addr ${service_addr}
  Restart=always
EOF

sudo tee /etc/systemd/system/consul_agent.service > /dev/null <<"EOF"
  [Unit]
  Description = "Consul Agent"
  
  [Service]
  KillSignal=INT
  ExecStart=/usr/local/bin/consul 
  Restart=always
EOF

sudo systemctl enable consul_agent.service
sudo systemctl start consul_agent.service
sudo systemctl enable consul_connect.service
sudo systemctl start consul_connect.service
