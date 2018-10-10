terraform {
  backend "atlas" {
    name = "niccorp/emojify-app"
  }
}

data "terraform_remote_state" "core" {
  backend = "atlas"

  config {
    name = "niccorp/emojify-core"
  }
}

provider "helm" {
  kubernetes {
    host = "${data.terraform_remote_state.core.k8s_host}"

    client_certificate     = "${base64decode(data.terraform_remote_state.core.k8s_client_certificate)}"
    client_key             = "${base64decode(data.terraform_remote_state.core.k8s_client_key)}"
    cluster_ca_certificate = "${base64decode(data.terraform_remote_state.core.k8s_cluster_ca_certificate)}"
  }
}

# Start our application
resource "helm_release" "emojify" {
  depends_on = ["null_resource.provision_secrets"]

  name    = "emojify"
  chart   = "${path.module}/helm_charts/emojify_helm"
  timeout = 600
  version = "0.3.0"

  set {
    name  = "machinebox_key"
    value = "${var.machinebox_key}"
  }

  set {
    name  = "domain"
    value = "${var.domain}"
  }

  set {
    name  = "version"
    value = "0.1.4"
  }

  set {
    name  = "api"
    value = "https://${var.domain}"
  }

  set {
    name  = "auth_replicas"
    value = "1"
  }

  set {
    name  = "api_replicas"
    value = "1"
  }

  set {
    name  = "router_replicas"
    value = "2"
  }

  set {
    name  = "website_replicas"
    value = "2"
  }

  set {
    name  = "facebox_replicas"
    value = "2"
  }
}
