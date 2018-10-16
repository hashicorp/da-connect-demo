/*
# Terraform enterprise remote state
terraform {
  backend "atlas" {
    name = "niccorp/emojify-core"
  }
}
*/

terraform {
  backend "azurerm" {
    key = "emojify.core.terraform.tfstate"
  }
}

resource "azurerm_resource_group" "core" {
  name     = "${var.resource_group_name}"
  location = "${var.location}"
}

module "network" {
  source              = "Azure/network/azurerm"
  location            = "${azurerm_resource_group.core.location}"
  resource_group_name = "${azurerm_resource_group.core.name}"
  address_space       = "10.0.0.0/16"
  subnet_prefixes     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  subnet_names        = ["data", "kubernetes", "vault"]
}

# Consul Helm chart
provider "helm" {
  kubernetes {
    host = "${azurerm_kubernetes_cluster.k8s.kube_config.0.host}"

    client_certificate     = "${base64decode(azurerm_kubernetes_cluster.k8s.kube_config.0.client_certificate)}"
    client_key             = "${base64decode(azurerm_kubernetes_cluster.k8s.kube_config.0.client_key)}"
    cluster_ca_certificate = "${base64decode(azurerm_kubernetes_cluster.k8s.kube_config.0.cluster_ca_certificate)}"
  }

  #install_tiller = true
  #  tiller_image   = "gcr.io/kubernetes-helm/tiller:v2.11.0"
}
