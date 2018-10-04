# Setup the intial Vault secrets required to enable the K8s and 
# VM auth endpoints

data "template_file" "provision_secrets" {
  template = "${file("${path.module}/scripts/provision_secrets.sh")}"

  vars {
    tennant_id                   = "${var.tennant_id}"
    client_id                    = "${var.client_id}"
    client_secret                = "${var.client_secret}"
    jumpbox_service_prinicpal_id = "${azurerm_user_assigned_identity.jumpbox_identity.principal_id}"
    k8s_cluster_ca_certificate   = "${base64decode(azurerm_kubernetes_cluster.k8s.kube_config.0.cluster_ca_certificate)}"
    k8s_host                     = "${azurerm_kubernetes_cluster.k8s.kube_config.0.host}"
    vault_token                  = "${var.vault_token}"
  }
}

resource "null_resource" "provision_secrets" {
  triggers {
    vault_id           = "${azurerm_virtual_machine.vault.id}"
    provision_vault_id = "${null_resource.provision_vault.id}"
    private_key_id     = "${tls_private_key.vault.id}"
    consul             = "${helm_release.consul.id}"
  }

  connection {
    host        = "${data.azurerm_public_ip.vault.ip_address}"
    type        = "ssh"
    user        = "ubuntu"
    private_key = "${tls_private_key.vault.private_key_pem}"
    agent       = false
  }

  provisioner "file" {
    content     = "${data.template_file.provision_secrets.rendered}"
    destination = "/tmp/provision_secrets.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/provision_secrets.sh",
      "sudo /tmp/provision_secrets.sh",
    ]
  }
}
