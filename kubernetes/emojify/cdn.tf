/*
# Configure cloud flare zone with IP address from kubernetes service
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
*/

