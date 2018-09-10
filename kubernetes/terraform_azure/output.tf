output "client_key" {
  value = "${coalesce(azurerm_kubernetes_cluster.k8s.kube_config.0.client_key,"empty")}"
}

output "client_certificate" {
  value = "${coalesce(azurerm_kubernetes_cluster.k8s.kube_config.0.client_certificate,"empty")}"
}

output "cluster_ca_certificate" {
  value = "${coalesce(azurerm_kubernetes_cluster.k8s.kube_config.0.cluster_ca_certificate,"empty")}"
}

output "username" {
  value = "${coalesce(azurerm_kubernetes_cluster.k8s.kube_config.0.username,"empty")}"
}

output "password" {
  value = "${coalesce(azurerm_kubernetes_cluster.k8s.kube_config.0.password,"empty")}"
}

output "kube_config" {
  value = "${coalesce(azurerm_kubernetes_cluster.k8s.kube_config_raw,"empty")}"
}

output "host" {
  value = "${azurerm_kubernetes_cluster.k8s.kube_config.0.host}"
}
