resource "azurerm_public_ip" "pip-ars" {
  name                = "pip-asr-${var.asr_virtual_network_name}"
  location            = data.azurerm_resource_group.resource-group.location
  resource_group_name = data.azurerm_resource_group.resource-group.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_route_server" "ars" {
  name                             = "ars-${var.asr_virtual_network_name}"
  location                         = data.azurerm_resource_group.resource-group.location
  resource_group_name              = data.azurerm_resource_group.resource-group.name
  sku                              = "Standard"
  public_ip_address_id             = azurerm_public_ip.pip-ars.id
  subnet_id                        = module.asr-vnet.vnet_subnets_name_id["RouteServerSubnet"]
  branch_to_branch_traffic_enabled = true
  tags                             = var.tags
}