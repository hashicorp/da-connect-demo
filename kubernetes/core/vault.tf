resource "tls_private_key" "vault" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

resource "azurerm_public_ip" "vault" {
  name                         = "vault-ip"
  location                     = "${azurerm_resource_group.core.location}"
  resource_group_name          = "${azurerm_resource_group.core.name}"
  public_ip_address_allocation = "Dynamic"
  idle_timeout_in_minutes      = 30

  tags {
    environment = "dev"
  }
}

resource "azurerm_network_interface" "vault" {
  name                = "vault-nic"
  location            = "${azurerm_resource_group.core.location}"
  resource_group_name = "${azurerm_resource_group.core.name}"

  ip_configuration {
    name                          = "vault_ip_config"
    subnet_id                     = "${module.network.vnet_subnets[2]}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.vault.id}"
  }
}

data "azurerm_subscription" "primary" {}

# ${data.azurerm_subscription.primary.public_ips.0.fqdn}

resource "random_string" "password" {
  length  = 32
  special = true
}

resource "azurerm_user_assigned_identity" "vault_identity" {
  location            = "${azurerm_resource_group.core.location}"
  resource_group_name = "${azurerm_resource_group.core.name}"

  name = "vault-vm"
}

data "azurerm_image" "vault" {
  name                = "vault"
  resource_group_name = "${var.images_resource_group}"
}

resource "azurerm_virtual_machine" "vault" {
  name                  = "vault-vm"
  location              = "${azurerm_resource_group.core.location}"
  resource_group_name   = "${azurerm_resource_group.core.name}"
  network_interface_ids = ["${azurerm_network_interface.vault.id}"]
  vm_size               = "Standard_DS1_v2"

  delete_os_disk_on_termination = true

  storage_image_reference {
    id = "${data.azurerm_image.vault.0.id}"
  }

  storage_os_disk {
    name              = "vaultosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "vault"
    admin_username = "ubuntu"
    admin_password = "Password1234!"
  }

  # Enable azure managed identity for AD
  identity {
    type         = "UserAssigned"
    identity_ids = ["${azurerm_user_assigned_identity.vault_identity.id}"]
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/ubuntu/.ssh/authorized_keys"
      key_data = "${tls_private_key.vault.public_key_openssh}"
    }
  }

  tags {
    environment = "dev"
  }
}

# IP Addresses are not allocated until attached to the VM so use a datasource to get round this
data "azurerm_public_ip" "vault" {
  name                = "${azurerm_public_ip.vault.name}"
  resource_group_name = "${azurerm_resource_group.core.name}"
  depends_on          = ["azurerm_virtual_machine.vault"]
}

data "template_file" "provision" {
  template = "${file("${path.module}/scripts/provision_vault.sh")}"

  vars {
    kube_config = "${azurerm_kubernetes_cluster.k8s.0.kube_config_raw}"
  }
}

resource "null_resource" "provision_vault" {
  triggers {
    vault_id       = "${azurerm_virtual_machine.vault.id}"
    private_key_id = "${tls_private_key.vault.id}"
    consul         = "${helm_release.consul.id}"
  }

  connection {
    host        = "${data.azurerm_public_ip.vault.ip_address}"
    type        = "ssh"
    user        = "ubuntu"
    private_key = "${tls_private_key.vault.private_key_pem}"
    agent       = false
  }

  provisioner "file" {
    content     = "${data.template_file.provision.rendered}"
    destination = "/tmp/provision.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/provision.sh",
      "sudo /tmp/provision.sh",
    ]
  }
}
