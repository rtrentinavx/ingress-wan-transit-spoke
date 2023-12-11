module "loadbalancer-external" {
  depends_on             = [azurerm_virtual_machine.firewall-1, azurerm_virtual_machine.firewall-2]
  source                 = "Azure/loadbalancer/azurerm"
  version                = "4.4.0"
  type                   = "public"
  disable_outbound_snat  = true
  frontend_name          = "sdwan-external-lb-${data.azurerm_resource_group.sdwan-resource-group.location}"
  resource_group_name    = data.azurerm_resource_group.sdwan-resource-group.name
  location               = data.azurerm_resource_group.sdwan-resource-group.location
  lb_floating_ip_enabled = true
  lb_port                = var.lb_port
  lb_probe               = var.lb_probe
  lb_sku                 = "Standard"
  pip_sku                = "Standard"
  prefix                 = "sdwan-external-lb-${data.azurerm_resource_group.sdwan-resource-group.location}"
  tags                   = var.tags
}

resource "azurerm_lb_backend_address_pool_address" "lb_pool_address_firewall-external-firewall-1" {
  name                    = var.firewall_name[0]
  backend_address_pool_id = module.loadbalancer-external.azurerm_lb_backend_address_pool_id
  virtual_network_id      = module.sdwan-vnet.vnet_id
  ip_address              = cidrhost(var.sdwan_subnet_prefixes[0], 4)
}

resource "azurerm_lb_backend_address_pool_address" "lb_pool_address_firewall-external-firewall-2" {
  name                    = var.firewall_name[1]
  backend_address_pool_id = module.loadbalancer-external.azurerm_lb_backend_address_pool_id
  virtual_network_id      = module.sdwan-vnet.vnet_id
  ip_address              = cidrhost(var.sdwan_subnet_prefixes[0], 5)
}

resource "azurerm_lb_outbound_rule" "lb_outbound_rule-external" {
  name                    = "sdwan-external-lb-outboundrule"
  backend_address_pool_id = module.loadbalancer-external.azurerm_lb_backend_address_pool_id
  enable_tcp_reset        = true
  loadbalancer_id         = module.loadbalancer-external.azurerm_lb_id
  protocol                = "All"

  frontend_ip_configuration {
    name = "sdwan-external-lb-${data.azurerm_resource_group.sdwan-resource-group.location}"
  }
}

# module "loadbalancer-internal" {
#   depends_on = [ azurerm_virtual_machine.firewall-1, azurerm_virtual_machine.firewall-2 ]
#   source                 = "Azure/loadbalancer/azurerm"
#   version                = "4.4.0"
#   type                   = "private"
#   disable_outbound_snat = true 
#   frontend_subnet_id     = module.vnet.vnet_subnets_name_id["privatesubnet"]
#   frontend_name          = "sdwan-internal-lb-${data.azurerm_resource_group.sdwan-resource-group.location}"
#   frontend_private_ip_address_allocation = "Static"
#   frontend_private_ip_address = cidrhost(var.subnet_prefixes[1], 6)
#   resource_group_name    = data.azurerm_resource_group.sdwan-resource-group.name
#   location               = data.azurerm_resource_group.sdwan-resource-group.location
#   lb_floating_ip_enabled = true
#   lb_port                = { haport = ["0", "All", "0"] }
#   lb_probe               = var.lb_probe
#   lb_sku                 = "Standard"
#   pip_sku                = "Standard"
#   prefix                 = "sdwan-internal-lb-${data.azurerm_resource_group.sdwan-resource-group.location}"
#   tags                   = var.tags
# }

# resource "azurerm_lb_backend_address_pool_address" "lb_pool_address_firewall-internal-firewall-1" {
#   name                    = var.firewall_name[0]
#   backend_address_pool_id = module.loadbalancer-internal.azurerm_lb_backend_address_pool_id
#   virtual_network_id      = module.vnet.vnet_id
#   ip_address              = cidrhost(var.subnet_prefixes[1], 4)
# }

# resource "azurerm_lb_backend_address_pool_address" "lb_pool_address_firewall-internal-firewall-2" {
#   name                    = var.firewall_name[1]
#   backend_address_pool_id = module.loadbalancer-internal.azurerm_lb_backend_address_pool_id
#   virtual_network_id      = module.vnet.vnet_id
#   ip_address              = cidrhost(var.subnet_prefixes[1], 5)
# }