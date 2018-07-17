output "config_raw" {
  value = "${module.kubernetes.kube_config}"
}

/*
output "consul_ip" {
  value = "${kubernetes_service.consul_server.load_balancer_ingress.0.ip}"
}
*/

