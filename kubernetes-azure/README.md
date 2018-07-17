# Consul Connect Demo on Kubernetes

## Create Cluster

```bash
terraform apply
```

## Fetch K8s config

```bash
./helper.sh config

```

## Set env var

```bash
export KUBECONFIG=$(pwd)/kube_config.yml
```

## Add applications

```bash
kubectl apply -f config/consul_server.yml
kubectl apply -f config/consul_agent.yml
kubectl apply -f config/consul_register.yml
kubectl apply -f config/router.yml
kubectl apply -f config/emojify_api.yml
kubectl apply -f config/emojify_facebox.yml
kubectl apply -f config/emojify_website.yml

```

## Open dashboard

```bash
kubectl proxy &
./helper dashboard
```

The consul server and router create external load balancers, the details can be found by navigating to the 
Kubernetes dashboard and viewing `services`.
