# Configure cloud flare zone with IP address from kubernetes service

data "azurerm_public_ips" "kubernetes" {
  resource_group_name = "MC_${data.terraform_remote_state.core.resource_group_name}_emojify_${data.terraform_remote_state.core.location}"
  name_prefix         = "kubernetes"
  attached            = true
  depends_on          = ["helm_release.emojify"]
}

resource "cloudflare_record" "root" {
  domain  = "${var.cloudflare_zone_id}"
  name    = "@"
  value   = "${data.azurerm_public_ips.kubernetes.public_ips.0.ip_address}"
  type    = "A"
  proxied = true
}
