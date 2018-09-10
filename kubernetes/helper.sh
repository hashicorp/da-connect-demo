#!/bin/bash

case $1 in
  config)
    echo "$(terraform output k8s_config)" > kube_config.yml
    ;;

  dashboard)
    echo "Make sure you are running kube proxy \"kubectl proxy\" before running this command"
    open "http://localhost:8001/api/v1/namespaces/kube-system/services/http:kubernetes-dashboard:/proxy/#!/overview?namespace=default"
    ;;

  consul_ui)
    echo "Make sure you are port forwarding with kubectl before running this command \"kubectl port-forward svc/consul-ui 8080:80\""
    open "http://localhost:8080/ui"
    ;;

  install_helm_provider)
    mkdir -p ./.terraform/plugins/darwin_amd64
    wget https://github.com/mcuadros/terraform-provider-helm/releases/download/v0.5.1/terraform-provider-helm_v0.5.1_darwin_amd64.tar.gz
    tar -xvf terraform-provider-helm*.tar.gz
    mv ./terraform-provider-helm_darwin_amd64/terraform-provider-helm ./.terraform/plugins/darwin_amd64
    rm ./terraform-provider-helm_v0.5.1_darwin_amd64.tar.gz
    rm -rf ./terraform-provider-helm_darwin_amd64
    ;;
esac
