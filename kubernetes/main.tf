resource "azurerm_resource_group" "k8s" {
  name     = "${var.resource_group_name}"
  location = "${var.location}"
}

module "network" {
  source              = "Azure/network/azurerm"
  location            = "${azurerm_resource_group.k8s.location}"
  resource_group_name = "${azurerm_resource_group.k8s.name}"
  address_space       = "10.0.0.0/16"
  subnet_prefixes     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  subnet_names        = ["subnet1", "subnet2", "subnet3"]
}

# Kubernetes cluster
module "k8s" {
  source = "./terraform_azure"

  resource_group_name = "${azurerm_resource_group.k8s.name}"
  location            = "${azurerm_resource_group.k8s.location}"
  client_id           = "${var.client_id}"
  client_secret       = "${var.client_secret}"
  subnet_id           = "${module.network.vnet_subnets[1]}"
}

# Consul Helm chart
provider "helm" {
  kubernetes {
    host     = "${module.k8s.host}"
    username = "${module.k8s.username}"
    password = "${module.k8s.password}"

    client_certificate     = "${base64decode(module.k8s.client_certificate)}"
    client_key             = "${base64decode(module.k8s.client_key)}"
    cluster_ca_certificate = "${base64decode(module.k8s.cluster_ca_certificate)}"
  }
}

# Run consul on kubernetes
resource "helm_release" "consul" {
  name  = "consul"
  chart = "./consul-helm"
}

# Start our application
resource "helm_release" "emojify" {
  name  = "emojify"
  chart = "./emojify-helm"

  set {
    name  = "machinebox_key"
    value = "${var.machinebox_key}"
  }
}
