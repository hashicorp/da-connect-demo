resource "tls_private_key" "server" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

resource "azurerm_public_ip" "vault" {
  name                         = "vault-ip"
  location                     = "${var.location}"
  resource_group_name          = "${var.resource_group_name}"
  public_ip_address_allocation = "Dynamic"
  idle_timeout_in_minutes      = 30

  tags {
    environment = "dev"
  }
}

resource "azurerm_network_interface" "vault" {
  name                = "vault-nic"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"

  ip_configuration {
    name                          = "vault_ip_config"
    subnet_id                     = "${var.subnet_id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.vault.id}"
  }
}

resource "azurerm_virtual_machine" "vault" {
  name                  = "vault-vm"
  location              = "${var.location}"
  resource_group_name   = "${var.resource_group_name}"
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
    name              = "myosdisk1"
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
      key_data = "${tls_private_key.server.public_key_openssh}"
    }
  }

  tags {
    environment = "dev"
  }
}

resource "tls_private_key" "vault" {
  algorithm = "ECDSA"
}

resource "tls_self_signed_cert" "vault" {
  key_algorithm   = "${tls_private_key.vault.algorithm}"
  private_key_pem = "${tls_private_key.vault.private_key_pem}"

  # Certificate expires after 240 hours.
  validity_period_hours = 240

  # Generate a new certificate if Terraform is run within three
  # hours of the certificate's expiration time.
  early_renewal_hours = 3

  # Reasonable set of uses for a server SSL certificate.
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]

  dns_names    = ["localhost", "vault.service.consul"]
  ip_addresses = ["127.0.0.1", "${azurerm_network_interface.vault.private_ip_address}", "${azurerm_public_ip.vault.ip_address}"]

  subject {
    common_name  = "vault.service.consul"
    organization = "HashiCorp Examples"
  }
}

resource "null_resource" "provision_vault" {
  triggers {
    ids = "${azurerm_virtual_machine.vault.id}${tls_private_key.vault.id}0"
  }

  connection {
    host        = "${azurerm_public_ip.vault.ip_address}"
    type        = "ssh"
    user        = "ubuntu"
    private_key = "${tls_private_key.server.private_key_pem}"
  }

  # Add the certificate which will be used to secure vault comms
  provisioner "file" {
    content     = "${tls_self_signed_cert.vault.cert_pem}"
    destination = "/tmp/cert.pem"
  }

  # Add the key which will be used to secure vault comms
  provisioner "file" {
    content     = "${tls_private_key.vault.private_key_pem}"
    destination = "/tmp/key.pem"
  }

  provisioner "file" {
    content     = "${file("${path.module}/scripts/source_vault.sh")}"
    destination = "/tmp/source_vault.sh"
  }

  provisioner "remote-exec" {
    script = "${path.module}/scripts/provision.sh"
  }
}
