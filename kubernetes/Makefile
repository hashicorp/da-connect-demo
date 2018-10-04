# Install the helm provider from the community repository
install_helm_provider:
	mkdir -p ./core/.terraform/plugins/darwin_amd64
	mkdir -p ./emojify/.terraform/plugins/darwin_amd64
	wget https://github.com/mcuadros/terraform-provider-helm/releases/download/v0.5.1/terraform-provider-helm_v0.5.1_darwin_amd64.tar.gz
	tar -xvf terraform-provider-helm*.tar.gz
	cp ./terraform-provider-helm_darwin_amd64/terraform-provider-helm ./.terraform/plugins/darwin_amd64
	rm ./terraform-provider-helm_v0.5.1_darwin_amd64.tar.gz
	rm -rf ./terraform-provider-helm_darwin_amd64

# Terraform apply the core infrastructure, creates the Kubernetes, Vault, Consul setup
apply_core:
	terraform init ./core
	terraform apply -state=./core/terraform.tfstate ./core

# Terraform destroy the core infrastructure
destroy_core:
	terraform init ./core
	terraform destroy -state=./core/terraform.tfstate ./core

# Terraform apply the application infrastructure, creates the Emojify app and required data stores
apply_app:
	terraform init ./emojify
	terraform apply -state=./emojify/terraform.tfstate ./emojify

# Terraform destroy the application infrastructure
destroy_app:
	terraform init ./emojify
	terraform destroy -state=./emojify/terraform.tfstate ./emojify

# Open the Kubernetes dashboard, runs kubectl proxy in the background
open_dashboard: get_k8s_config
	@KUBECONFIG=$(shell pwd)/kube_config.yml kubectl proxy & echo $$! > .pid_kube_proxy
	sleep 3
	@echo "Opening dashboard, To quit, press Ctrl-C"
	@open "http://localhost:8001/api/v1/namespaces/kube-system/services/http:kubernetes-dashboard:/proxy/#!/overview?namespace=default"
	@bash -c "trap 'pkill -F .pid_kube_proxy' SIGINT SIGTERM ERR EXIT; sleep 20000"

# Open the Consul UI, runs kubectl port forward in the background
open_consul_ui: get_k8s_config
	@KUBECONFIG=$(shell pwd)/kube_config.yml kubectl port-forward svc/consul-ui 8080:80 & echo $$! > .pid_kube_ports
	@echo "Opening Consul UI, To quit, press Ctrl-C"
	@sleep 3
	@open "http://localhost:8080/ui"
	@bash -c "trap 'pkill -F .pid_kube_ports' SIGINT SIGTERM ERR EXIT; sleep 20000"

open_vault_ui: tunnel_vault_start
	@echo "Opening Vault UI, To quit, press Ctrl-C"
	@sleep 3
	@open "http://localhost:8202/ui"
	@bash -c "trap 'ssh -S vault-ctrl-socket -O exit ubuntu@$(shell terraform output -state=./core/terraform.tfstate vault_host)' SIGINT SIGTERM ERR EXIT; sleep 20000"

# Open the application in your browser
open_app: get_k8s_config
	@echo "Opening application homepage"
	@open "http://$(shell KUBECONFIG=`pwd`/kube_config.yml kubectl get services router --template="{{(index .status.loadBalancer.ingress 0).ip}}")"

# Fetch the kubernetes config from the core state
get_k8s_config:
	@echo "Fetching kubernetes config from core state"
	@$(shell echo "`terraform output -state=./core/terraform.tfstate k8s_config`" > kube_config.yml)

# Get the Vault private key from the terraform output and write to disk
get_vault_private_key:
	@$(shell echo "`terraform output -state=./core/terraform.tfstate vault_key`" > vault_key.pem)
	@chmod 0600 ./vault_key.pem

get_jumpbox_private_key:
	@$(shell echo "`terraform output -state=./core/terraform.tfstate jumpbox_key`" > jumpbox_key.pem)
	@chmod 0600 ./jumpbox_key.pem

# Open an SSH session to the Vault server
ssh_vault: get_vault_private_key
	@echo "Logging into Vault server"
	@ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ./vault_key.pem ubuntu@$(shell terraform output -state=./core/terraform.tfstate vault_host)

# Create an SSH tunnel to the Vault server
tunnel_vault_start: get_vault_private_key
	@echo "Starting SSH tunnel to Vault server"
	@ssh -M -S vault-ctrl-socket -fnNT -o ExitOnForwardFailure=yes -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -L 8202:localhost:8200 -i ./vault_key.pem ubuntu@$(shell terraform output -state=./core/terraform.tfstate vault_host)
	@echo "SSH Tunnel open, set the following environment variables to access vault locally"
	@echo "export VAULT_ADDR=http://localhost:8202"
	@echo "export VAULT_TOKEN=mytoken"

# Stop the SSH tunnel to the Vault Server
tunnel_vault_stop:
	@echo "Stopping SSH tunnel to Vault server"
	@ssh -S vault-ctrl-socket -O exit ubuntu@$(shell terraform output -state=./core/terraform.tfstate vault_host)


# Open an SSH session to the Vault server
ssh_jumpbox: get_jumpbox_private_key
	@echo "Logging into Jumpbox server"
	@ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ./jumpbox_key.pem ubuntu@$(shell terraform output -state=./core/terraform.tfstate jumpbox_host)
