data_dir= "/tmp/consul_demo"

connect {
  enabled = true
}

retry_join = ["consul_server"]
