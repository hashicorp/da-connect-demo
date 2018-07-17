data_dir= "/tmp/consul"

bootstrap = true

connect {
  enabled = true
  proxy {
   allow_managed_api_registration = true
   allow_managed_root = true
  }
}

server = true
ui = true

