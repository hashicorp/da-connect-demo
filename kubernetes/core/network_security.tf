resource "azurerm_network_security_group" "connect" {
  name                = "networkSegments"
  location            = "${azurerm_resource_group.core.location}"
  resource_group_name = "${azurerm_resource_group.core.name}"

  tags {
    environment = "dev"
  }
}
