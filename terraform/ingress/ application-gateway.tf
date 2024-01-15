locals {
  backend_address_pool_name      = "${module.vnet.vnet_name}-beap"
  frontend_port_name             = "${module.vnet.vnet_name}-feport"
  frontend_ip_configuration_name = "${module.vnet.vnet_name}-feip"
  http_setting_name              = "${module.vnet.vnet_name}-be-htst"
  listener_name                  = "${module.vnet.vnet_name}-httplstn"
  request_routing_rule_name      = "${module.vnet.vnet_name}-rqrt"
  redirect_configuration_name    = "${module.vnet.vnet_name}-rdrcfg"
}

resource "azurerm_public_ip" "pip-appgw" {
  name                = "pip-${var.appgw_name}"
  resource_group_name = data.azurerm_resource_group.resource-group.name
  location            = data.azurerm_resource_group.resource-group.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_application_gateway" "appgw" {
  name                = var.appgw_name
  resource_group_name = data.azurerm_resource_group.resource-group.name
  location            = data.azurerm_resource_group.resource-group.location

  sku {
    name     = var.appgw_sku_size
    tier     = var.appgw_sku_tier
    capacity = var.appgw_sku_capacity
  }

  gateway_ip_configuration {
    name      = "ip-configuration-${var.appgw_name}"
    subnet_id = module.vnet.vnet_subnets_name_id["frontend"]
  }

  frontend_port {
    name = local.frontend_port_name
    port = var.appgw_fe-port
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.pip-appgw.id
  }

  backend_address_pool {
    name         = local.backend_address_pool_name
    #ip_addresses = ["${cidrhost(var.subnet_prefixes[3], 4)}", "${cidrhost(var.subnet_prefixes[3], 5)}"] firewalls 
    ip_addresses = []

  }

  probe {
    name                                      = "probe-${var.appgw_name}"
    interval                                  = var.appgw_probe-interval
    protocol                                  = var.appgw_be-protocol
    path                                      = var.appgw_be-path
    timeout                                   = 3 * var.appgw_probe-interval
    unhealthy_threshold                       = 3
    port                                      = 8008
    pick_host_name_from_backend_http_settings = true
  }

  backend_http_settings {
    name                                = local.http_setting_name
    cookie_based_affinity               = "Disabled"
    path                                = var.appgw_be-path
    port                                = var.appgw_be-port
    protocol                            = var.appgw_be-protocol
    request_timeout                     = 3 * var.appgw_probe-interval
    probe_name                          = "probe-${var.appgw_name}"
    pick_host_name_from_backend_address = true
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = var.appgw_fe-protocol
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    priority                   = 9
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
  }
}