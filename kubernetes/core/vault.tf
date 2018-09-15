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

resource "azurerm_virtual_machine" "vault" {
  name                  = "vault-vm"
  location              = "${azurerm_resource_group.core.location}"
  resource_group_name   = "${azurerm_resource_group.core.name}"
  network_interface_ids = ["${azurerm_network_interface.vault.id}"]
  vm_size               = "Standard_DS1_v2"

  delete_os_disk_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
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

resource "null_resource" "provision_vault" {
  triggers {
    ids = "${azurerm_virtual_machine.vault.id}${tls_private_key.vault.id}"
  }

  connection {
    host        = "${azurerm_public_ip.vault.ip_address}"
    type        = "ssh"
    user        = "ubuntu"
    private_key = "${tls_private_key.vault.private_key_pem}"
  }

  provisioner "remote-exec" {
    script = "${path.module}/scripts/provision.sh"
  }
}
