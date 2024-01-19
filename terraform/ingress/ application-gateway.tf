locals {
  backend_address_pool_name      = "${module.vnet.vnet_name}-beap"
  frontend_port_name             = "${module.vnet.vnet_name}-feport"
  frontend_ip_configuration_name = "${module.vnet.vnet_name}-feip"
  http_setting_name              = "${module.vnet.vnet_name}-be-htst"
  listener_name                  = "${module.vnet.vnet_name}-httplstn"
  request_routing_rule_name      = "${module.vnet.vnet_name}-rqrt"
  redirect_configuration_name    = "${module.vnet.vnet_name}-rdrcfg"
}

resource "azurerm_user_assigned_identity" "appgw_user_assigned" {
  location            = data.azurerm_resource_group.resource-group.location
  resource_group_name = data.azurerm_resource_group.resource-group.name
  name                = "user-assigned-identity-${var.appgw_name}"
  tags                = var.tags
}

resource "azurerm_role_assignment" "appgw_user_assigned_role_assignment" {
  scope                = data.azurerm_key_vault.keyvault.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.appgw_user_assigned.id
}

resource "azurerm_public_ip" "pip-appgw" {
  name                = "pip-${var.appgw_name}"
  resource_group_name = data.azurerm_resource_group.resource-group.name
  location            = data.azurerm_resource_group.resource-group.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_application_gateway" "appgw" {
  name                = var.appgw_name
  resource_group_name = data.azurerm_resource_group.resource-group.name
  location            = data.azurerm_resource_group.resource-group.location

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.appgw_user_assigned.id]
  }

  ssl_certificate {
    name                = data.azurerm_key_vault_certificate.cert.name
    key_vault_secret_id = data.azurerm_key_vault_certificate.cert.secret_id
  }

  sku {
    name     = var.appgw_sku_size
    tier     = var.appgw_sku_tier
    capacity = var.appgw_sku_capacity
    #Possible values are Standard_Small, Standard_Medium, Standard_Large, Standard_v2, WAF_Medium, WAF_Large, and WAF_v2.
    #Possible values are Standard, Standard_v2, WAF and WAF_v2.
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
    name = local.backend_address_pool_name
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
    ssl_certificate_name           = var.appgw_fe-protocol == "Https" ? data.azurerm_key_vault_certificate.cert.name : null
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    priority                   = 9
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
  }

  waf_configuration {
    enabled          = var.appgw_sku_tier == "WAF_v2" ? true : false
    firewall_mode    = "detection"
    rule_set_version = "3.2"
    #Possible values are 0.1, 1.0, 2.1, 2.2.9, 3.0, 3.1 and 3.2. 
  }

  tags = var.tags
}