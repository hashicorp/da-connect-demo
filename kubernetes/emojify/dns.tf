data "azurerm_public_ips" "kubernetes" {
  resource_group_name = "MC_${data.terraform_remote_state.core.resource_group_name}_emojify_${data.terraform_remote_state.core.location}"
  name_prefix         = "kubernetes"
  attached            = true
  depends_on          = ["helm_release.emojify"]
}

/*
resource "dnsimple_record" "emojify" {
  domain = "${var.dnsimple_domain}"
  name   = ""
  value  = "${data.azurerm_public_ips.kubernetes.public_ips.0.ip_address}"
  type   = "A"
  ttl    = 60
}

resource "dnsimple_record" "emojify_api" {
  domain = "${var.dnsimple_domain}"
  name   = "api"
  value  = "${data.azurerm_public_ips.kubernetes.public_ips.0.ip_address}"
  type   = "A"
  ttl    = 60
}
*/

