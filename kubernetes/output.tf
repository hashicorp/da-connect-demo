output "k8s_client_key" {
  value = "${coalesce(module.k8s.client_key,"empty")}"
}

output "k8s_client_certificate" {
  value = "${coalesce(module.k8s.client_certificate,"empty")}"
}

output "k8s_cluster_ca_certificate" {
  value = "${coalesce(module.k8s.cluster_ca_certificate,"empty")}"
}

output "k8s_username" {
  value = "${coalesce(module.k8s.username,"empty")}"
}

output "k8s_password" {
  value = "${coalesce(module.k8s.password,"empty")}"
}

output "k8s_config" {
  value = "${coalesce(module.k8s.kube_config,"empty")}"
}

output "k8s_host" {
  value = "${module.k8s.host}"
}
