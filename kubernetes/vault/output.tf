output "server_key" {
  value = "${tls_private_key.server.private_key_pem}"
}

output "host" {
  value = "${azurerm_public_ip.vault.ip_address}"
}
