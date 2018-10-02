resource "azurerm_redis_cache" "emojify_cache" {
  name                = "emojify-redis"
  resource_group_name = "${data.terraform_remote_state.core.resource_group_name}"
  location            = "${data.terraform_remote_state.core.location}"
  capacity            = 0
  family              = "C"
  sku_name            = "Basic"
  enable_non_ssl_port = true

  redis_configuration {
    maxmemory_policy = "volatile-lru"
  }
}

/*
# Lock the redis service down to the connect proxies ip address
resource "azurerm_redis_firewall_rule" "emojify_cache" {
  name                = "redisconnect"
  redis_cache_name    = "${azurerm_redis_cache.emojify_cache.name}"
  resource_group_name = "${data.terraform_remote_state.core.resource_group_name}"
  start_ip            = "0.0.0.0"
  end_ip              = "0.0.0.0"
}
*/

