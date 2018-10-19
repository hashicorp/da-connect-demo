resource "tls_private_key" "payment" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

resource "azurerm_public_ip" "payment" {
  name                         = "payment-ip"
  resource_group_name          = "${data.terraform_remote_state.core.resource_group_name}"
  location                     = "${data.terraform_remote_state.core.location}"
  public_ip_address_allocation = "Dynamic"
  idle_timeout_in_minutes      = 30

  tags {
    environment = "dev"
  }
}

resource "azurerm_network_interface" "payment" {
  name                = "payment-nic"
  resource_group_name = "${data.terraform_remote_state.core.resource_group_name}"
  location            = "${data.terraform_remote_state.core.location}"

  ip_configuration {
    name                          = "payment_ip_config"
    subnet_id                     = "${data.terraform_remote_state.core.subnet_ids[0]}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.payment.id}"
  }
}

resource "random_string" "password_payment" {
  length  = 32
  special = true
}

data "azurerm_image" "payment" {
  name                = "payment"
  resource_group_name = "${var.images_resource_group}"
}

/*
resource "azurerm_image" "test" {
  name                      = "acctest"
  location                  = "West US"
  resource_group_name       = "${data.terraform_remote_state.core.resource_group_name}"
  source_virtual_machine_id = "${azure_image.payment.id}"
}
*/

resource "azurerm_virtual_machine" "payment" {
  name                  = "payment-vm"
  resource_group_name   = "${data.terraform_remote_state.core.resource_group_name}"
  location              = "${data.terraform_remote_state.core.location}"
  network_interface_ids = ["${azurerm_network_interface.payment.id}"]
  vm_size               = "Standard_DS1_v2"

  delete_os_disk_on_termination = true

  storage_image_reference {
    id = "${data.azurerm_image.payment.0.id}"
  }

  storage_os_disk {
    name              = "paymentosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "payment"
    admin_username = "ubuntu"
    admin_password = "${random_string.password_payment.result}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/ubuntu/.ssh/authorized_keys"
      key_data = "${tls_private_key.payment.public_key_openssh}"
    }
  }

  tags {
    environment = "dev"
  }
}

# IP Addresses are not allocated until attached to the VM so use a datasource to get round this
data "azurerm_public_ip" "payment" {
  name                = "${azurerm_public_ip.payment.name}"
  resource_group_name = "${data.terraform_remote_state.core.resource_group_name}"
  depends_on          = ["azurerm_virtual_machine.payment"]
}

data "template_file" "provision_payment" {
  template = "${file("${path.module}/scripts/provision_payment.sh")}"

  vars {
    kube_config = "${data.terraform_remote_state.core.k8s_config}"
  }
}

resource "null_resource" "provision_payment" {
  triggers {
    payment_id = "${azurerm_virtual_machine.payment.id}"
  }

  connection {
    host        = "${data.azurerm_public_ip.payment.ip_address}"
    type        = "ssh"
    user        = "ubuntu"
    private_key = "${tls_private_key.payment.private_key_pem}"
    agent       = false
  }

  provisioner "file" {
    content     = "${data.template_file.provision_payment.rendered}"
    destination = "/tmp/provision.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/provision.sh",
      "sudo /tmp/provision.sh",
    ]
  }
}
