resource "tls_private_key" "jumpbox" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

resource "azurerm_public_ip" "jumpbox" {
  name                         = "jumpbox-ip"
  location                     = "${azurerm_resource_group.core.location}"
  resource_group_name          = "${azurerm_resource_group.core.name}"
  public_ip_address_allocation = "Dynamic"
  idle_timeout_in_minutes      = 30

  tags {
    environment = "dev"
  }
}

resource "azurerm_network_interface" "jumpbox" {
  name                = "jumpbox-nic"
  location            = "${azurerm_resource_group.core.location}"
  resource_group_name = "${azurerm_resource_group.core.name}"

  ip_configuration {
    name                          = "jumpbox_ip_config"
    subnet_id                     = "${module.network.vnet_subnets[2]}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.jumpbox.id}"
  }
}

resource "random_string" "password_jumpbox" {
  length  = 32
  special = true
}

# Create an MSI identiry to allow authentication with Vault
resource "azurerm_user_assigned_identity" "jumpbox_identity" {
  location            = "${azurerm_resource_group.core.location}"
  resource_group_name = "${azurerm_resource_group.core.name}"

  name = "jumpbox-vm"
}

data "azurerm_image" "jumpbox" {
  name                = "jumpbox"
  resource_group_name = "${var.images_resource_group}"
}

resource "azurerm_virtual_machine" "jumpbox" {
  name                  = "jumpbox-vm"
  location              = "${azurerm_resource_group.core.location}"
  resource_group_name   = "${azurerm_resource_group.core.name}"
  network_interface_ids = ["${azurerm_network_interface.jumpbox.id}"]
  vm_size               = "Standard_DS1_v2"

  delete_os_disk_on_termination = true

  storage_image_reference {
    id = "${data.azurerm_image.jumpbox.0.id}"
  }

  storage_os_disk {
    name              = "jumpboxosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "jumpbox"
    admin_username = "ubuntu"
    admin_password = "${random_string.password_jumpbox.result}"
  }

  # Enable azure managed identity for AD
  identity {
    type         = "UserAssigned"
    identity_ids = ["${azurerm_user_assigned_identity.jumpbox_identity.id}"]
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/ubuntu/.ssh/authorized_keys"
      key_data = "${tls_private_key.jumpbox.public_key_openssh}"
    }
  }

  tags {
    environment = "dev"
  }
}

# IP Addresses are not allocated until attached to the VM so use a datasource to get round this
data "azurerm_public_ip" "jumpbox" {
  name                = "${azurerm_public_ip.jumpbox.name}"
  resource_group_name = "${azurerm_resource_group.core.name}"
  depends_on          = ["azurerm_virtual_machine.jumpbox"]
}

data "template_file" "provision_jumpbox" {
  template = "${file("${path.module}/scripts/provision_jumpbox.sh")}"

  vars {
    kube_config       = "${azurerm_kubernetes_cluster.k8s.0.kube_config_raw}"
    kube_ca_cert      = "${base64decode(azurerm_kubernetes_cluster.k8s.kube_config.0.cluster_ca_certificate)}"
    letsencrypt_email = "${var.letsencrypt_email}"
  }
}

resource "null_resource" "provision_jumpbox" {
  triggers {
    vault_id       = "${azurerm_virtual_machine.vault.id}"
    jumpbox_id     = "${azurerm_virtual_machine.jumpbox.id}"
    private_key_id = "${tls_private_key.jumpbox.id}"
    consul         = "${helm_release.consul.id}"
  }

  connection {
    host        = "${data.azurerm_public_ip.jumpbox.ip_address}"
    type        = "ssh"
    user        = "ubuntu"
    private_key = "${tls_private_key.jumpbox.private_key_pem}"
    agent       = false
  }

  provisioner "file" {
    content     = "${data.template_file.provision_jumpbox.rendered}"
    destination = "/tmp/provision.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/provision.sh",
      "sudo /tmp/provision.sh",
    ]
  }
}
