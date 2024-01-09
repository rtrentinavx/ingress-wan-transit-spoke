resource "azurerm_public_ip" "pip-vng-1" {
  count               = var.express_route_location ? 1 : 0
  name                = "pip-vng-1-${var.ars_virtual_network_name}"
  location            = data.azurerm_resource_group.ars-resource-group.location
  resource_group_name = data.azurerm_resource_group.ars-resource-group.name
  allocation_method   = "Dynamic"
}

resource "azurerm_public_ip" "pip-vng-2" {
  count               = var.express_route_location ? 1 : 0
  name                = "pip-vng-2-${var.ars_virtual_network_name}"
  location            = data.azurerm_resource_group.ars-resource-group.location
  resource_group_name = data.azurerm_resource_group.ars-resource-group.name
  allocation_method   = "Dynamic"
}

resource "azurerm_virtual_network_gateway" "vng" {
  count               = var.express_route_location ? 1 : 0
  name                = var.vng_name
  location            = data.azurerm_resource_group.ars-resource-group.location
  resource_group_name = data.azurerm_resource_group.ars-resource-group.name

  type = var.vpn_gateway_type

  active_active = true
  enable_bgp    = true
  sku           = var.vpn_sku

  generation = "Generation2"

  bgp_settings {
    asn         = azurerm_route_server.ars.virtual_router_asn
    peer_weight = 0
  }

  ip_configuration {
    name                          = "vnetGatewayConfig1"
    public_ip_address_id          = azurerm_public_ip.pip-vng-1[0].id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = module.ars-vnet.vnet_subnets_name_id["GatewaySubnet"]
  }

  ip_configuration {
    name                          = "vnetGatewayConfig2"
    public_ip_address_id          = azurerm_public_ip.pip-vng-2[0].id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = module.ars-vnet.vnet_subnets_name_id["GatewaySubnet"]
  }
}