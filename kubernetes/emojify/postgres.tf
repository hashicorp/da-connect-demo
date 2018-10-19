resource "azurerm_postgresql_server" "emojify_db" {
  name                = "emojify-db"
  resource_group_name = "${data.terraform_remote_state.core.resource_group_name}"
  location            = "${data.terraform_remote_state.core.location}"

  sku {
    name     = "B_Gen5_1"
    capacity = 1
    tier     = "Basic"
    family   = "Gen5"
  }

  storage_profile {
    storage_mb            = 5120
    backup_retention_days = 7
    geo_redundant_backup  = "Disabled"
  }

  administrator_login          = "psqladminun"
  administrator_login_password = "H@Sh1CoR3!"
  version                      = "9.5"
  ssl_enforcement              = "Disabled"
}

resource "azurerm_postgresql_database" "emojify_db" {
  name                = "keratin"
  resource_group_name = "${data.terraform_remote_state.core.resource_group_name}"
  server_name         = "${azurerm_postgresql_server.emojify_db.name}"

  charset   = "UTF8"
  collation = "English_United States.1252"
}

# Allow internal ingress
resource "azurerm_postgresql_firewall_rule" "emojify_db" {
  name                = "azure"
  resource_group_name = "${data.terraform_remote_state.core.resource_group_name}"
  server_name         = "${azurerm_postgresql_server.emojify_db.name}"
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

/*
resource "tls_private_key" "emojify_db" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

resource "azurerm_public_ip" "emojify_db" {
  name                         = "db-connect-ip"
  resource_group_name          = "${data.terraform_remote_state.core.resource_group_name}"
  location                     = "${data.terraform_remote_state.core.location}"
  public_ip_address_allocation = "Dynamic"
  idle_timeout_in_minutes      = 30

  tags {
    environment = "dev"
  }
}

resource "azurerm_network_interface" "emojify_db" {
  name                = "db-connect-nic"
  resource_group_name = "${data.terraform_remote_state.core.resource_group_name}"
  location            = "${data.terraform_remote_state.core.location}"

  ip_configuration {
    name                          = "db_connect_ip_config"
    subnet_id                     = "${data.terraform_remote_state.core.subnet_ids[0]}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.emojify_db.id}"
  }
}

resource "azurerm_virtual_machine" "emojify_db" {
  name                  = "db-connect-vm"
  resource_group_name   = "${data.terraform_remote_state.core.resource_group_name}"
  location              = "${data.terraform_remote_state.core.location}"
  network_interface_ids = ["${azurerm_network_interface.emojify_db.id}"]
  vm_size               = "Standard_DS1_v2"

  delete_os_disk_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "redisosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "db"
    admin_username = "ubuntu"
    admin_password = "Password1234!"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/ubuntu/.ssh/authorized_keys"
      key_data = "${tls_private_key.emojify_db.public_key_openssh}"
    }
  }

  tags {
    environment = "dev"
  }
}

data "azurerm_public_ip" "emojify_db" {
  name                = "${azurerm_public_ip.emojify_db.name}"
  resource_group_name = "${data.terraform_remote_state.core.resource_group_name}"
  depends_on          = ["azurerm_virtual_machine.emojify_db"]
}

data "template_file" "provision" {
  template = "${file("${path.module}/scripts/provision.sh")}"

  vars {
    consul_version = "1.2.3"
    service_addr   = "${azurerm_postgresql_server.emojify_db.fqdn}"
    listen_addr    = "${azurerm_network_interface.emojify_db.private_ip_address}:8443"
  }
}

resource "null_resource" "connect_provision" {
  triggers {
    database_id        = "${azurerm_virtual_machine.emojify_db.id}"
    private_key        = "${tls_private_key.emojify_db.id}"
    postgres_server_id = "${azurerm_postgresql_server.emojify_db.id}"
  }

  connection {
    host        = "${data.azurerm_public_ip.emojify_db.ip_address}"
    type        = "ssh"
    user        = "ubuntu"
    private_key = "${tls_private_key.emojify_db.private_key_pem}"
    agent       = false
  }

  # Add the certificate which will be used to secure vault comms
  provisioner "file" {
    content     = "${data.template_file.provision.rendered}"
    destination = "/tmp/provision.sh"
  }
}
*/

