resource "azurerm_redis_cache" "emojify" {
  name                = "emojify-redis"
  resource_group_name = "${var.resource_group_name}"
  location            = "${var.location}"
  capacity            = 1000
  family              = "C"
  sku_name            = "Basic"
  enable_non_ssl_port = false

  redis_configuration {
    maxmemory_reserved = 2
    maxmemory_delta    = 2
    maxmemory_policy   = "volatile-lru"
  }
}

resource "azurerm_redis_firewall_rule" "emojify" {
  name                = "redisconnect"
  redis_cache_name    = "${azurerm_redis_cache.emojify.name}"
  resource_group_name = "${var.resource_group_name}"
  start_ip            = "1.2.3.4"
  end_ip              = "2.3.4.5"
}

# Add Consul Connect Proxy
# Note, could we use a container group?
resource "tls_private_key" "server" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

resource "azurerm_public_ip" "redis" {
  name                         = "redis-connect-ip"
  location                     = "${var.location}"
  resource_group_name          = "${var.resource_group_name}"
  public_ip_address_allocation = "Dynamic"
  idle_timeout_in_minutes      = 30

  tags {
    environment = "dev"
  }
}

resource "azurerm_network_interface" "redis" {
  name                = "redis-connect-nic"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"

  ip_configuration {
    name                          = "redis_connect_ip_config"
    subnet_id                     = "${var.data_subnet_id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.redis.id}"
  }
}

resource "azurerm_virtual_machine" "emojify" {
  name                  = "redis-connect-vm"
  location              = "${var.location}"
  resource_group_name   = "${var.resource_group_name}"
  network_interface_ids = ["${azurerm_network_interface.redis.id}"]
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
