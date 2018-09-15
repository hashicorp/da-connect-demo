/*
resource "azurerm_redis_cache" "emojify_cache" {
  name                = "emojify-redis"
  resource_group_name = "${var.resource_group_name}"
  location            = "${var.location}"
  capacity            = 0
  family              = "C"
  sku_name            = "Basic"
  enable_non_ssl_port = true

  redis_configuration {
    maxmemory_policy = "volatile-lru"
  }
}

# Lock the redis service down to the connect proxies ip address
resource "azurerm_redis_firewall_rule" "emojify_cache" {
  name                = "redisconnect"
  redis_cache_name    = "${azurerm_redis_cache.emojify_cache.name}"
  resource_group_name = "${var.resource_group_name}"
  start_ip            = "${azurerm_network_interface.emojify_cache.private_ip_address}"
  end_ip              = "${azurerm_network_interface.emojify_cache.private_ip_address}"
}

# Add Consul Connect Proxy
# Note, could we use a container group?
resource "tls_private_key" "server" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

resource "azurerm_public_ip" "emojify_cache" {
  name                         = "redis-connect-ip"
  location                     = "${var.location}"
  resource_group_name          = "${var.resource_group_name}"
  public_ip_address_allocation = "Dynamic"
  idle_timeout_in_minutes      = 30

  tags {
    environment = "dev"
  }
}

resource "azurerm_network_interface" "emojify_cache" {
  name                = "redis-connect-nic"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"

  ip_configuration {
    name                          = "redis_connect_ip_config"
    subnet_id                     = "${var.data_subnet_id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.emojify_cache.id}"
  }
}

resource "azurerm_virtual_machine" "emojify_cache" {
  name                  = "redis-connect-vm"
  location              = "${var.location}"
  resource_group_name   = "${var.resource_group_name}"
  network_interface_ids = ["${azurerm_network_interface.emojify_cache.id}"]
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
    computer_name  = "redis-connect"
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

data "template_file" "provision" {
  template = "${file("${path.module}/scripts/provision.sh")}"

  vars {
    consul_version = "1.2.3"
    service_addr   = "${azurerm_redis_cache.emojify_cache.private_static_ip_address}:${azurerm_redis_cache.emojify_cache.port}"
    listen_addr    = "${azurerm_network_interface.emojify_cache.private_ip_address}:8443"
  }
}

resource "null_resource" "connect_provision" {
  triggers {
    ids = "${azurerm_virtual_machine.emojify_cache.id}${tls_private_key.server.id}${azurerm_redis_cache.emojify_cache.id}"
  }

  connection {
    host        = "${azurerm_public_ip.emojify_cache.ip_address}"
    type        = "ssh"
    user        = "ubuntu"
    private_key = "${tls_private_key.server.private_key_pem}"
  }

  # Add the certificate which will be used to secure vault comms
  provisioner "file" {
    content     = "${data.template_file.provision.rendered}"
    destination = "/tmp/provision.sh"
  }
}
*/

