#! /bin/bash -e

# Add K8s config
mkdir -p /home/ubuntu/.kube
echo "${kube_config}" > /home/ubuntu/.kube/config
echo "${kube_ca_cert}" > /home/ubuntu/.kube/cluster_ca_certificate.pem

# Configure Vault Auto Auth
tee /home/ubuntu/.vault-auto-auth > /dev/null <<"EOF"
    "auto_auth" {
      method "azure" {
        config {
          role = "jumpbox-role"
					resource = "https://management.azure.com/"
        }
      }

      sink "file" {
        config {
          path = "/home/ubuntu/.vault_token"
        }
      }
    }
EOF

chown -R ubuntu /home/ubuntu

# Enable KubeDNS for Consul
cat <<EOF | KUBECONFIG=/home/ubuntu/.kube/config kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  labels:
    addonmanager.kubernetes.io/mode: EnsureExists
  name: kube-dns
  namespace: kube-system
data:
  stubDomains: |
    {"consul": ["$(KUBECONFIG=/home/ubuntu/.kube/config kubectl get svc consul-dns -o jsonpath='{.spec.clusterIP}')"]}
EOF

# Enable Certmanager
cat <<EOF | KUBECONFIG=/home/ubuntu/.kube/config kubectl apply -f -
---
apiVersion: certmanager.k8s.io/v1alpha1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: ${letsencrypt_email}
    privateKeySecretRef:
      name: letsencrypt-prod
    http01: {}
EOF


systemctl restart consul
systemctl restart vault-auto-auth

# Update profile
echo "export KUBECONFIG=/home/ubuntu/.kube/config" >> /home/ubuntu/.profile
echo "export VAULT_ADDR=http://vault.service.consul:8200" >> /home/ubuntu/.profile
echo 'export VAULT_TOKEN=$(cat /home/ubuntu/.vault_token)' >> /home/ubuntu/.profile
