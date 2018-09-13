/*
provider "vault" {
  address = "http://${var.vault_ip}:8200"
  token   = "${var.vault_token}"
}

resource "vault_generic_secret" "emojify" {
  path = "secret/emojify"

  data_json = <<EOT
{
  "machinebox_key":   "${var.machinebox_key}"
}
EOT
}
*/

