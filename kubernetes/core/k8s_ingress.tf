resource "random_string" "domain" {
  length  = 10
  special = false
  upper   = false
  number  = false
}

# Create a public ip for the k8s ingress
resource "azurerm_public_ip" "ingress_ip" {
  name                         = "ingress-pip"
  location                     = "${azurerm_resource_group.core.location}"
  resource_group_name          = "MC_${azurerm_resource_group.core.name}_emojify_${azurerm_resource_group.core.location}"
  public_ip_address_allocation = "Static"
  idle_timeout_in_minutes      = 30
  domain_name_label            = "${random_string.domain.result}"

  tags {
    environment = "dev"
  }
}

resource "helm_repository" "incubator" {
  name = "incubator"
  url  = "https://kubernetes-charts-incubator.storage.googleapis.com/"
}

resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "${helm_repository.incubator.metadata.0.name}"
  chart      = "stable/cert-manager"
  namespace  = "kube-system"

  set {
    name  = "rbac.create"
    value = "false"
  }

  set {
    name  = "ingressShim.defaultIssuerName"
    value = "letsencrypt-staging"
  }

  set {
    name  = "ingressShim.defaultIssuerKind"
    value = "ClusterIssuer"
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }
}

resource "helm_release" "nginx_ingress" {
  name       = "nginx-ingress"
  repository = "${helm_repository.incubator.metadata.0.name}"
  chart      = "stable/nginx-ingress"
  namespace  = "kube-system"

  set {
    name  = "rbac.create"
    value = "false"
  }

  set {
    name  = "controller.service.loadBalancerIP"
    value = "${azurerm_public_ip.ingress_ip.ip_address}"
  }
}
