install_helm_provider: install_helm_provider_darwin install_helm_provider_linux

# Install the helm provider from the community repository
install_helm_provider_linux:
	mkdir -p ./core/.terraform/plugins/linux_amd64
	mkdir -p ./emojify/.terraform/plugins/linux_amd64
	wget https://github.com/mcuadros/terraform-provider-helm/releases/download/v0.6.0/terraform-provider-helm_v0.6.0_linux_amd64.tar.gz
	tar -xvf terraform-provider-helm*.tar.gz
	cp ./terraform-provider-helm_linux_amd64/terraform-provider-helm ./core/.terraform/plugins/linux_amd64
	cp ./terraform-provider-helm_linux_amd64/terraform-provider-helm ./emojify/.terraform/plugins/linux_amd64
	rm ./terraform-provider-helm_v0.6.0_linux_amd64.tar.gz
	rm -rf ./terraform-provider-helm_linux_amd64

install_helm_provider_darwin:
	mkdir -p ./core/.terraform/plugins/darwin_amd64
	mkdir -p ./emojify/.terraform/plugins/darwin_amd64
	wget https://github.com/mcuadros/terraform-provider-helm/releases/download/v0.6.0/terraform-provider-helm_v0.6.0_darwin_amd64.tar.gz
	tar -xvf terraform-provider-helm*.tar.gz
	cp ./terraform-provider-helm_darwin_amd64/terraform-provider-helm ./core/.terraform/plugins/darwin_amd64
	cp ./terraform-provider-helm_darwin_amd64/terraform-provider-helm ./emojify/.terraform/plugins/darwin_amd64
	rm ./terraform-provider-helm_v0.6.0_darwin_amd64.tar.gz
	rm -rf ./terraform-provider-helm_darwin_amd64

update_consul_helm_chart:
	wget https://github.com/hashicorp/consul-helm/archive/v0.3.0.zip
	unzip v0.3.0.zip
	rm -rf ./core/helm_charts/consul_helm
	mv consul-helm-0.3.0 ./core/helm_charts/consul_helm/
	rm v0.3.0.zip

setup_remote_state:
	@rm -rf ./remotestatebackend.tfvars
	@rm -rf ./remotestatedata.tfvars

	@echo "Type the name of the azure resource group where your storage account is located"
	@read storage; \
	  echo "resource_group_name = \"$${storage}\"" >> ./remotestatebackend.tfvars; \
	  echo "remote_state_resource_group_name = \"$${storage}\"" >> ./remotestatedata.tfvars
	@echo ""
	
	@echo "Type the name of the storage account to use for remote state"
	@read storage; \
	  echo "storage_account_name = \"$${storage}\"" >> ./remotestatebackend.tfvars; \
	  echo "remote_state_storage_account_name = \"$${storage}\"" >> ./remotestatedata.tfvars
	@echo ""
	
	@echo "Type the name of the container to use for remote state"
	@read storage; \
	  echo "container_name = \"$${storage}\"" >> ./remotestatebackend.tfvars; \
	  echo "remote_state_container_name = \"$${storage}\"" >> ./remotestatedata.tfvars
	@echo ""
	@echo "Remote state setup, you can modify remotestatebackend.tfvars and remotestatedata.tfvars if needed"
	

# Terraform apply the core infrastructure, creates the Kubernetes, Vault, Consul setup
apply_core:
	cd core && terraform init -backend-config=../remotestatebackend.tfvars
	cd core && terraform apply

# Terraform destroy the core infrastructure
destroy_core:
	cd core && terraform init -backend-config=../remotestatebackend.tfvars
	cd core && terraform destroy

# Terraform apply the application infrastructure, creates the Emojify app and required data stores
apply_emojify:
	cd emojify && terraform init -backend-config=../remotestatebackend.tfvars
	cd emojify && terraform apply -var-file=../remotestatedata.tfvars

# Terraform destroy the application infrastructure
destroy_emojify:
	cd emojify && terraform init -backend-config=../remotestatebackend.tfvars
	cd emojify && terraform destroy -var-file=../remotestatedata.tfvars

# Open the Kubernetes dashboard, runs kubectl proxy in the background
open_dashboard: get_k8s_config
	@KUBECONFIG=$(shell pwd)/kube_config.yml kubectl proxy & echo $$! > .pid_kube_proxy
	sleep 3
	@echo "Opening dashboard, To quit, press Ctrl-C"
	@open "http://localhost:8001/api/v1/namespaces/kube-system/services/http:kubernetes-dashboard:/proxy/#!/overview?namespace=default"
	@bash -c "trap 'pkill -F .pid_kube_proxy' SIGINT SIGTERM ERR EXIT; sleep 20000"

# Open the Consul UI, runs kubectl port forward in the background
open_consul_ui: get_k8s_config
	@KUBECONFIG=$(shell pwd)/kube_config.yml kubectl port-forward svc/consul-ui 8502:80 & echo $$! > .pid_kube_ports
	@echo "Opening Consul UI, To quit, press Ctrl-C"
	@sleep 3
	@open "http://localhost:8502/ui"
	@bash -c "trap 'pkill -F .pid_kube_ports' SIGINT SIGTERM ERR EXIT; sleep 20000"

open_vault_ui: tunnel_vault_start
	@echo "Opening Vault UI, To quit, press Ctrl-C"
	@sleep 3
	@open "http://localhost:8202/ui"
	@bash -c "trap 'ssh -S vault-ctrl-socket -O exit ubuntu@$(shell cd core && terraform output vault)' SIGINT SIGTERM ERR EXIT; sleep 20000"

# Open the application in your browser
open_app: get_k8s_config
	@echo "Opening application homepage"
	@open "http://$(shell KUBECONFIG=`pwd`/kube_config.yml kubectl get services router --template="{{(index .status.loadBalancer.ingress 0).ip}}")"

# Open an SSH session to the Vault server
ssh_vault: get_vault_private_key
	@echo "Logging into Vault server"
	@ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ./vault_key.pem ubuntu@$(shell cd core && terraform output vault_host)

# Create an SSH tunnel to the Vault server
tunnel_vault_start: get_vault_private_key
	@echo "Starting SSH tunnel to Vault server"
	@ssh -M -S vault-ctrl-socket -fnNT -o ExitOnForwardFailure=yes -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -L 8202:localhost:8200 -i ./vault_key.pem ubuntu@$(shell cd core && terraform output vault_host)
	@echo "SSH Tunnel open, set the following environment variables to access vault locally"
	@echo "export VAULT_ADDR=http://localhost:8202"
	@echo "export VAULT_TOKEN=mytoken"

# Stop the SSH tunnel to the Vault Server
tunnel_vault_stop:
	@echo "Stopping SSH tunnel to Vault server"
	@ssh -S vault-ctrl-socket -O exit ubuntu@$(shell cd core && terraform output vault_host)

# Open an SSH session to the Jumpbox server
ssh_jumpbox: get_jumpbox_private_key
	@echo "Logging into Jumpbox server"
	ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ./jumpbox_key.pem ubuntu@$(shell cd core && terraform output jumpbox_host)

ssh_payment: get_payment_private_key
	@echo "Logging into Payment server"
	ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ./payment_key.pem ubuntu@$(shell cd emojify && terraform output payment_host)

# Fetch the kubernetes config from the core state
get_k8s_config:
	@echo "Fetching kubernetes config from core state"
	$(call terraform_output, k8s_config) > ./kube_config.yml

# Get the Vault private key from the terraform output and write to disk
get_vault_private_key:
	$(call terraform_output, vault_key) > vault_key.pem
	@chmod 0600 ./vault_key.pem

get_jumpbox_private_key:
	$(call terraform_output, jumpbox_key) > jumpbox_key.pem
	@chmod 0600 ./jumpbox_key.pem

get_payment_private_key:
	$(call terraform_emojify_output, payment_key) > payment_key.pem
	@chmod 0600 ./payment_key.pem

define terraform_output
	@bash -c "cd core && terraform output $(1)"
endef

define terraform_emojify_output
	@bash -c "cd emojify && terraform output $(1)"
endef
