module "loadbalancer" {
  depends_on             = [azurerm_virtual_machine.activefgtvm, azurerm_virtual_machine.passivefgtvm]
  source                 = "Azure/loadbalancer/azurerm"
  version                = "4.4.0"
  type                   = "public"
  disable_outbound_snat = true 
  frontend_name          = "ingress-lb-${data.azurerm_resource_group.resource-group.location}"
  resource_group_name    = data.azurerm_resource_group.resource-group.name
  location               = data.azurerm_resource_group.resource-group.location
  lb_floating_ip_enabled = true
  lb_port                = var.lb_port
  lb_probe               = var.lb_probe
  lb_sku                 = "Standard"
  pip_sku                = "Standard"
  prefix                 = "ingress-lb-${data.azurerm_resource_group.resource-group.location}"
  tags                   = var.tags
}

resource "azurerm_lb_backend_address_pool_address" "lb_pool_address_firewall-active" {
  name                    = var.firewall_name[0]
  backend_address_pool_id = module.loadbalancer.azurerm_lb_backend_address_pool_id
  virtual_network_id      = module.vnet.vnet_id
  ip_address              = cidrhost(var.subnet_prefixes[3], 4)
}

resource "azurerm_lb_backend_address_pool_address" "lb_pool_address_firewall-passive" {
  name                    = var.firewall_name[1]
  backend_address_pool_id = module.loadbalancer.azurerm_lb_backend_address_pool_id
  virtual_network_id      = module.vnet.vnet_id
  ip_address              = cidrhost(var.subnet_prefixes[3], 5)
}