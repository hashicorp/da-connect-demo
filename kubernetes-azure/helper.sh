#!/bin/bash

function fetch_config {
  echo "$(terraform output config_raw)" > kube_config.yml
}

case $1 in
  config)
    fetch_config;
    ;;

  dashboard)
    open "http://localhost:8001/api/v1/namespaces/kube-system/services/http:kubernetes-dashboard:/proxy/#!/overview?namespace=default"
    ;;

  consul)
    open "http://$(terraform output consul_ip)"
esac
