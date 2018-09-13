resource "azurerm_network_security_group" "connect" {
  name                = "networkSegments"
  location            = "${azurerm_resource_group.k8s.location}"
  resource_group_name = "${azurerm_resource_group.k8s.name}"

  tags {
    environment = "dev"
  }
}

resource "azurerm_network_security_rule" "vault" {
  name                        = "vault-sg"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "${module.vault.host}"
  resource_group_name         = "${azurerm_resource_group.k8s.name}"
  network_security_group_name = "${azurerm_network_security_group.connect.name}"
}
