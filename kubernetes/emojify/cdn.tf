# Configure cloud flare zone with IP address from kubernetes service
resource "azurerm_public_ip" "router_ip" {
  name                         = "router-pip"
  location                     = "${data.terraform_remote_state.core.location}"
  resource_group_name          = "MC_${data.terraform_remote_state.core.resource_group_name}_emojify_${data.terraform_remote_state.core.location}"
  public_ip_address_allocation = "Static"
  idle_timeout_in_minutes      = 30

  tags {
    environment = "dev"
  }
}

resource "azurerm_public_ip" "auth_ip" {
  name                         = "auth-pip"
  location                     = "${data.terraform_remote_state.core.location}"
  resource_group_name          = "MC_${data.terraform_remote_state.core.resource_group_name}_emojify_${data.terraform_remote_state.core.location}"
  public_ip_address_allocation = "Static"
  idle_timeout_in_minutes      = 30

  tags {
    environment = "dev"
  }
}

resource "cloudflare_record" "root" {
  domain  = "${var.cloudflare_zone_id}"
  name    = "@"
  value   = "${azurerm_public_ip.router_ip.ip_address}"
  type    = "A"
  proxied = true
}

resource "cloudflare_record" "auth" {
  domain  = "${var.cloudflare_zone_id}"
  name    = "auth"
  value   = "${azurerm_public_ip.auth_ip.ip_address}"
  type    = "A"
  proxied = true
}
