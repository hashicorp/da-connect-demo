# Simple Kubernetes Demo
This demo is a simplified example of the azure demo for Kubernetes, all services are connected using Consul Connect and Envoy.  You need to have Consul running on your K8s cluster using the HashiCorp Consul Helm charts.

## Provision secrets
Obtain your machine box key and set it to the environment variable `MB_KEY`

```
export MB_KEY="xxxxxxxxx"
```

Create a Kubernetes secret with this key
```
cat <<EOF | kubectl apply -f -
---
apiVersion: v1
kind: Secret
metadata:
  name: demo-secrets
type: Opaque
data:
  mb_key: $(echo ${MB_KEY} | base64)
EOF
```

## Run application
To run the application setup the pods in K8s

```bash
# Ingress (NGINX)
kubectl apply -f ingress.yml

# Face detection (Machinebox)
kubectl apply -f machinebox.yml

# API
kubectl apply -f api.yml

# Website
kubectl apply -f website.yml
```
