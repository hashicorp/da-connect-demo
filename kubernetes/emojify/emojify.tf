data "terraform_remote_state" "core" {
  backend = "local"

  config {
    path = "${path.module}/../core/terraform.tfstate"
  }
}

provider "helm" {
  kubernetes {
    host     = "${data.terraform_remote_state.core.k8s_host}"
    username = "${data.terraform_remote_state.core.k8s_username}"
    password = "${data.terraform_remote_state.core.k8s_password}"

    client_certificate     = "${base64decode(data.terraform_remote_state.core.k8s_client_certificate)}"
    client_key             = "${base64decode(data.terraform_remote_state.core.k8s_client_key)}"
    cluster_ca_certificate = "${base64decode(data.terraform_remote_state.core.k8s_cluster_ca_certificate)}"
  }
}

# Start our application
resource "helm_release" "emojify" {
  name    = "emojify"
  chart   = "${path.module}/helm_charts/emojify_helm"
  timeout = 1000

  set {
    name  = "machinebox_key"
    value = "${var.machinebox_key}"
  }
}
