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
