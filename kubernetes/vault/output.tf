output "server_ssh_private_key" {
  value = "${tls_private_key.server.private_key_pem}"
}

output "client_cert" {
  value = "${tls_self_signed_cert.vault.private_key_pem}"
}

output "client_key" {
  value = "${tls_private_key.vault.private_key_pem}"
}

output "token" {
  value = "${var.token}"
}

output "host" {
  value = "${azurerm_public_ip.vault.ip_address}"
}
