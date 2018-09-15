provider "azurerm" {}

resource "tls_private_key" "k8s" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

resource "azurerm_kubernetes_cluster" "k8s" {
  name                = "${var.cluster_name}"
  location            = "${azurerm_resource_group.core.location}"
  resource_group_name = "${azurerm_resource_group.core.name}"
  dns_prefix          = "${var.cluster_name}"

  linux_profile {
    admin_username = "ubuntu"

    ssh_key {
      key_data = "${tls_private_key.k8s.public_key_openssh}"
    }
  }

  agent_pool_profile {
    name            = "default"
    count           = "${var.agent_count}"
    vm_size         = "Standard_D2_v2"
    os_type         = "Linux"
    os_disk_size_gb = 30

    vnet_subnet_id = "${module.network.vnet_subnets[1]}"
  }

  # Advanced networking
  network_profile {
    network_plugin     = "azure"
    docker_bridge_cidr = "172.17.0.1/16"
    dns_service_ip     = "10.2.0.10"
    service_cidr       = "10.2.0.0/24"
  }

  service_principal {
    client_id     = "${var.client_id}"
    client_secret = "${var.client_secret}"
  }

  tags {
    Environment = "Development"
  }
}
