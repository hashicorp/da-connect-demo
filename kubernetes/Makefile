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
	@echo "Opening dashboard, To quit, press Ctrl-C"
	@open "http://localhost:8001/api/v1/namespaces/kube-system/services/http:kubernetes-dashboard:/proxy/#!/overview?namespace=default"
	@bash -c "trap 'pkill -F .pid_kube_proxy' SIGINT SIGTERM ERR EXIT; sleep 20000"

# Open the Consul UI, runs kubectl port forward in the background
open_consul_ui: get_k8s_config
	@kubectl port-forward svc/consul-ui 8080:80 & echo $$! > .pid_kube_ports
	@echo "Opening Consul UI, To quit, press Ctrl-C"
	@sleep 1
	@open "http://localhost:8080/ui"
	@bash -c "trap 'pkill -F .pid_kube_ports' SIGINT SIGTERM ERR EXIT; sleep 20000"

# Open the application in your browser
open_app: get_k8s_config
	@echo "Opening application homepage"
	@open "http://$(shell KUBECONFIG=`pwd`/kube_config.yml kubectl get services router --template="{{(index .status.loadBalancer.ingress 0).ip}}")"

# Fetch the kubernetes config from the core state
get_k8s_config:
	@echo "Fetching kubernetes config from core state"
	@$(shell echo "`terraform output -state=./core/terraform.tfstate k8s_config`" > kube_config.yml)
