module "loadbalancer-external" {
  depends_on = [ azurerm_virtual_machine.activefgtvm, azurerm_virtual_machine.passivefgtvm ]
  source                 = "Azure/loadbalancer/azurerm"
  version                = "4.4.0"
  type                   = "public"
  frontend_name          = "sdwan-external-lb-${data.azurerm_resource_group.resource-group.location}"
  resource_group_name    = data.azurerm_resource_group.resource-group.name
  location               = data.azurerm_resource_group.resource-group.location
  lb_floating_ip_enabled = true
  lb_port                = var.lb_port
  lb_probe               = var.lb_probe
  lb_sku                 = "Standard"
  pip_sku                = "Standard"
  prefix                 = "sdwan-external-lb-${data.azurerm_resource_group.resource-group.location}"
  tags                   = var.tags
}

resource "azurerm_lb_backend_address_pool_address" "lb_pool_address_firewall-external-active" {
  name                    = var.firewall_name[0]
  backend_address_pool_id = module.loadbalancer-external.azurerm_lb_backend_address_pool_id
  virtual_network_id      = module.vnet.vnet_id
  ip_address              = cidrhost(var.subnet_prefixes[0], 4)
}

resource "azurerm_lb_backend_address_pool_address" "lb_pool_address_firewall-external-passive" {
  name                    = var.firewall_name[1]
  backend_address_pool_id = module.loadbalancer-external.azurerm_lb_backend_address_pool_id
  virtual_network_id      = module.vnet.vnet_id
  ip_address              = cidrhost(var.subnet_prefixes[0], 5)
}

module "loadbalancer-internal" {
  depends_on = [ azurerm_virtual_machine.activefgtvm, azurerm_virtual_machine.passivefgtvm ]
  source                 = "Azure/loadbalancer/azurerm"
  version                = "4.4.0"
  type                   = "private"
  frontend_subnet_id     = module.vnet.vnet_subnets_name_id["privatesubnet"]
  frontend_name          = "sdwan-internal-lb-${data.azurerm_resource_group.resource-group.location}"
  frontend_private_ip_address = cidrhost(var.subnet_prefixes[1], 6)
  resource_group_name    = data.azurerm_resource_group.resource-group.name
  location               = data.azurerm_resource_group.resource-group.location
  lb_floating_ip_enabled = true
  lb_port                = { all = ["0", "All", "0"] }
  lb_probe               = var.lb_probe
  lb_sku                 = "Standard"
  pip_sku                = "Standard"
  prefix                 = "sdwan-internal-lb-${data.azurerm_resource_group.resource-group.location}"
  tags                   = var.tags
}

resource "azurerm_lb_backend_address_pool_address" "lb_pool_address_firewall-internal-active" {
  name                    = var.firewall_name[0]
  backend_address_pool_id = module.loadbalancer-internal.azurerm_lb_backend_address_pool_id
  virtual_network_id      = module.vnet.vnet_id
  ip_address              = cidrhost(var.subnet_prefixes[1], 4)
}

resource "azurerm_lb_backend_address_pool_address" "lb_pool_address_firewall-internal-passive" {
  name                    = var.firewall_name[1]
  backend_address_pool_id = module.loadbalancer-internal.azurerm_lb_backend_address_pool_id
  virtual_network_id      = module.vnet.vnet_id
  ip_address              = cidrhost(var.subnet_prefixes[1], 5)
}