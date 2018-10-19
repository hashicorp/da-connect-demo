# Configure cloud flare zone with IP address from kubernetes service
resource "cloudflare_record" "root" {
  count = "${var.cloudflare_enabled ? 1 : 0}"

  domain  = "${var.cloudflare_zone_id}"
  name    = "www"
  value   = "${data.terraform_remote_state.core.k8s_ingress_fqdn}"
  type    = "CNAME"
  proxied = true
}
