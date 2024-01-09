module "loadbalancer-external" {
  depends_on             = [azurerm_virtual_machine.firewall-1, azurerm_virtual_machine.firewall-2]
  source                 = "Azure/loadbalancer/azurerm"
  version                = "4.4.0"
  type                   = "public"
  disable_outbound_snat  = true
  frontend_name          = var.elb_frontend_ip_name
  resource_group_name    = data.azurerm_resource_group.sdwan-resource-group.name
  location               = data.azurerm_resource_group.sdwan-resource-group.location
  lb_floating_ip_enabled = true
  lb_port                = var.lb_port
  lb_probe               = var.lb_probe
  lb_sku                 = "Standard"
  pip_sku                = "Standard"
  name                   = var.elb_name
  tags                   = var.tags
}

resource "azurerm_network_interface_backend_address_pool_association" "pool_address_firewall-external-firewall-1" {
  network_interface_id    = azurerm_network_interface.firewall-1-port1.id
  ip_configuration_name   = "ipconfig1"
  backend_address_pool_id = module.loadbalancer-external.azurerm_lb_backend_address_pool_id
}

resource "azurerm_network_interface_backend_address_pool_association" "pool_address_firewall-external-firewall-2" {
  network_interface_id    = azurerm_network_interface.firewall-2-port1.id
  ip_configuration_name   = "ipconfig1"
  backend_address_pool_id = module.loadbalancer-external.azurerm_lb_backend_address_pool_id
}

resource "azurerm_lb_outbound_rule" "lb_outbound_rule-external" {
  name                     = "Allow-Outbound"
  backend_address_pool_id  = module.loadbalancer-external.azurerm_lb_backend_address_pool_id
  enable_tcp_reset         = true
  loadbalancer_id          = module.loadbalancer-external.azurerm_lb_id
  protocol                 = "All"
  idle_timeout_in_minutes  = "15"
  allocated_outbound_ports = "0"

  frontend_ip_configuration {
    name = var.elb_frontend_ip_name
  }
}