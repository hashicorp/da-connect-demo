data_dir= "/tmp/consul_demo"

connect {
  enabled = true
  proxy {
   allow_managed_api_registration = true
   allow_managed_root = true
  }
}

retry_join = ["consul_server"]
