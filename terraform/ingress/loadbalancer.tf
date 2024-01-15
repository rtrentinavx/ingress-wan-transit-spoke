module "loadbalancer-external" {
  depends_on             = [azurerm_virtual_machine.firewall-1, azurerm_virtual_machine.firewall-1]
  source                 = "Azure/loadbalancer/azurerm"
  version                = "4.4.0"
  type                   = "public"
  disable_outbound_snat  = true
  frontend_name          = "external-ingress-lb-${data.azurerm_resource_group.resource-group.location}"
  resource_group_name    = data.azurerm_resource_group.resource-group.name
  location               = data.azurerm_resource_group.resource-group.location
  lb_floating_ip_enabled = true
  lb_port                = var.lb_port
  lb_probe               = var.lb_probe
  lb_sku                 = "Standard"
  pip_sku                = "Standard"
  prefix                 = "ingress-external-lb-${data.azurerm_resource_group.resource-group.location}"
  tags                   = var.tags
}

module "loadbalancer-internal" {
  depends_on = [ azurerm_virtual_machine.firewall-1, azurerm_virtual_machine.firewall-2 ]
  source                 = "Azure/loadbalancer/azurerm"
  version                = "4.4.0"
  type                   = "private"
  disable_outbound_snat = true 
  frontend_subnet_id     = module.vnet.vnet_subnets_name_id["publicsubnet"]
  frontend_name          = "ingress-internal-lb-${data.azurerm_resource_group.resource-group.location}"
  frontend_private_ip_address_allocation = "Static"
  frontend_private_ip_address = cidrhost(var.subnet_prefixes[3], 4)
  resource_group_name    = data.azurerm_resource_group.resource-group.name
  location               = data.azurerm_resource_group.resource-group.location
  lb_floating_ip_enabled = true
  lb_port                = { haport = ["0", "All", "0"] }
  lb_probe               = var.lb_probe
  lb_sku                 = "Standard"
  pip_sku                = "Standard"
  prefix                 = "ingress-internal-lb-${data.azurerm_resource_group.resource-group.location}"
  tags                   = var.tags
 }

resource "azurerm_lb_backend_address_pool_address" "external-lb_pool_address_firewall-active" {
  name                    = var.firewall_name[0]
  backend_address_pool_id = module.loadbalancer-external.azurerm_lb_backend_address_pool_id
  virtual_network_id      = module.vnet.vnet_id
  ip_address              = cidrhost(var.subnet_prefixes[3], 5)
}

resource "azurerm_lb_backend_address_pool_address" "external-lb_pool_address_firewall-passive" {
  name                    = var.firewall_name[1]
  backend_address_pool_id = module.loadbalancer-external.azurerm_lb_backend_address_pool_id
  virtual_network_id      = module.vnet.vnet_id
  ip_address              = cidrhost(var.subnet_prefixes[3], 6)
}

resource "azurerm_lb_backend_address_pool_address" "internal-lb_pool_address_firewall-active" {
  name                    = var.firewall_name[0]
  backend_address_pool_id = module.loadbalancer-internal.azurerm_lb_backend_address_pool_id
  virtual_network_id      = module.vnet.vnet_id
  ip_address              = cidrhost(var.subnet_prefixes[3], 5)
}

resource "azurerm_lb_backend_address_pool_address" "internal-lb_pool_address_firewall-passive" {
  name                    = var.firewall_name[1]
  backend_address_pool_id = module.loadbalancer-internal.azurerm_lb_backend_address_pool_id
  virtual_network_id      = module.vnet.vnet_id
  ip_address              = cidrhost(var.subnet_prefixes[3], 6)
}