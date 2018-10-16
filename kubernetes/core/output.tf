output "k8s_client_key" {
  value = "${azurerm_kubernetes_cluster.k8s.kube_config.0.client_key}"
}

output "k8s_client_certificate" {
  value = "${azurerm_kubernetes_cluster.k8s.kube_config.0.client_certificate}"
}

output "k8s_cluster_ca_certificate" {
  value = "${azurerm_kubernetes_cluster.k8s.kube_config.0.cluster_ca_certificate}"
}

output "k8s_username" {
  value = "${azurerm_kubernetes_cluster.k8s.kube_config.0.username}"
}

output "k8s_password" {
  value = "${azurerm_kubernetes_cluster.k8s.kube_config.0.password}"
}

output "k8s_config" {
  value = "${azurerm_kubernetes_cluster.k8s.0.kube_config_raw}"
}

output "k8s_host" {
  value = "${azurerm_kubernetes_cluster.k8s.kube_config.0.host}"
}

output "k8s_ingress_ip" {
  value = "${azurerm_public_ip.ingress_ip.ip_address}"
}

output "k8s_ingress_fqdn" {
  value = "${azurerm_public_ip.ingress_ip.fqdn}"
}

output "vault_host" {
  value = "${data.azurerm_public_ip.vault.ip_address}"
}

output "vault_key" {
  value = "${tls_private_key.vault.private_key_pem}"
}

output "jumpbox_host" {
  value = "${data.azurerm_public_ip.jumpbox.ip_address}"
}

output "jumpbox_key" {
  value = "${tls_private_key.jumpbox.private_key_pem}"
}

output "vault_service_prinicpal_id" {
  value = "${azurerm_user_assigned_identity.vault_identity.principal_id}"
}

output "jumpbox_service_prinicpal_id" {
  value = "${azurerm_user_assigned_identity.jumpbox_identity.principal_id}"
}

output "resource_group_name" {
  value = "${azurerm_resource_group.core.name}"
}

output "location" {
  value = "${azurerm_resource_group.core.location}"
}

output "subnet_ids" {
  value = "${module.network.vnet_subnets}"
}
