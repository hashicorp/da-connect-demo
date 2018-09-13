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
