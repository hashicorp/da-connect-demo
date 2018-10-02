resource "azurerm_network_security_group" "connect" {
  name                = "networkSegments"
  location            = "${azurerm_resource_group.core.location}"
  resource_group_name = "${azurerm_resource_group.core.name}"

  tags {
    environment = "dev"
  }
}

# allow inbound connections to vault server
resource "azurerm_network_security_rule" "vault" {
  name                        = "vault-sr"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "8200"
  source_address_prefix       = "10.0.0.0/16"
  destination_address_prefix  = "${azurerm_network_interface.vault.private_ip_address}"
  network_security_group_name = "${azurerm_network_security_group.connect.name}"
  resource_group_name         = "${azurerm_resource_group.core.name}"
}
