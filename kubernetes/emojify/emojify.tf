data "terraform_remote_state" "core" {
  backend = "local"

  config {
    path = "${path.module}/../core/terraform.tfstate"
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
  version = "v0.1.15"

  set {
    name  = "machinebox_key"
    value = "${var.machinebox_key}"
  }
}
