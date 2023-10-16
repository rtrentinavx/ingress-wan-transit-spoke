
resource "azurerm_resource_group" "terraform-azure-resource-group" {
  name     = var.resource_group
  location = var.location
  tags     = var.tags
}

resource "azurerm_virtual_network" "terraform-azure-virtual_network" {
  depends_on = [
    azurerm_resource_group.terraform-azure-resource-group
  ]
  name                = var.virtual_network_name
  resource_group_name = azurerm_resource_group.terraform-azure-resource-group.name
  address_space       = var.address_space
  location            = azurerm_resource_group.terraform-azure-resource-group.location
  tags                = var.tags
}

resource "azurem_subnet" "terraform-azure-subnet" {
  depends_on = [
    azurerm_virtual_network.terraform-azure-virtual_network
  ]
  for_each             = var.subnet
  resource_group_name  = azurerm_resource_group.terraform-azure-resource-group.name
  virtual_network_name = azurerm_virtual_network.terraform-azure-virtual_network.name
  name                 = each.value.name
  address_prefixes     = each.value.address_prefixes
  tags                 = var.tags
}

resource "azurerm_public_ip" "ars_pip" {
  name                = "pip-asr-${var.virtual_network_name}"
  location            = azurerm_resource_group.terraform-azure-resource-group.location
  resource_group_name = azurerm_resource_group.terraform-azure-resource-group.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_route_server" "ars" {
  name                             = "ars-${var.virtual_network_name}"
  location                         = azurerm_resource_group.terraform-azure-resource-group.location
  resource_group_name              = azurerm_resource_group.terraform-azure-resource-group.name
  sku                              = "Standard"
  public_ip_address_id             = azurerm_public_ip.ars_pip.id
  subnet_id                        = azurerm_subnet.terraform-azure-subnet.subnet_id[subnet01]
  branch_to_branch_traffic_enabled = true
  tags                             = var.tags
}

resource "azurerm_public_ip" "vng_pip_1" {
  name                = "vng-pip-1"
  location            = azurerm_resource_group.terraform-azure-resource-group.location
  resource_group_name = azurerm_resource_group.terraform-azure-resource-group.name
  allocation_method   = "Dynamic"
}

resource "azurerm_public_ip" "vng_pip_2" {
  name                = "vng-pip-2"
  location            = azurerm_resource_group.terraform-azure-resource-group.location
  resource_group_name = azurerm_resource_group.terraform-azure-resource-group.name
  allocation_method   = "Dynamic"
}

resource "azurerm_virtual_network_gateway" "this" {
  name                = var.vng_name
  location            = azurerm_resource_group.terraform-azure-resource-group.location
  resource_group_name = azurerm_resource_group.terraform-azure-resource-group.name

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = true
  enable_bgp    = true
  sku           = "VpnGw2"

  generation = "Generation2"

  bgp_settings {
    asn         = azurerm_route_server.ars.virtual_router_asn
    peer_weight = 0

    peering_addresses {
      ip_configuration_name = "vnetGatewayConfig1"
      apipa_addresses       = [var.vng_primary_tunnel_ip]
    }
    peering_addresses {
      ip_configuration_name = "vnetGatewayConfig2"
      apipa_addresses       = [var.vng_ha_tunnel_ip]
    }

  }

  ip_configuration {
    name                          = "vnetGatewayConfig1"
    public_ip_address_id          = azurerm_public_ip.vng_pip_1.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.terraform-azure-subnet.subnet_id[subnet02]
  }

  ip_configuration {
    name                          = "vnetGatewayConfig2"
    public_ip_address_id          = azurerm_public_ip.vng_pip_2.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.terraform-azure-subnet.subnet_id[subnet02]
  }
}

resource "azurerm_virtual_network_peering" "transit_1_to_vng" {
  name                         = "transit-1-to-vng"
  resource_group_name          = azurerm_resource_group.this.name
  virtual_network_name         = module.mc-transit-1.vpc.name
  remote_virtual_network_id    = azurerm_virtual_network.ars_vng.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = true
  depends_on = [
    azurerm_virtual_network_gateway.this
  ]
}

resource "azurerm_virtual_network_peering" "vng_to_transit_1" {
  name                         = "vng-to-spoke"
  resource_group_name          = azurerm_resource_group.this.name
  virtual_network_name         = azurerm_virtual_network.ars_vng.name
  remote_virtual_network_id    = module.mc-transit-1.vpc.azure_vnet_resource_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  depends_on = [
    azurerm_virtual_network_gateway.this
  ]
}

# resource "time_sleep" "wait_60_seconds" {
#   depends_on = [
#     azurerm_virtual_network_peering.transit_1_to_vng,
#     azurerm_virtual_network_peering.vng_to_transit_1
#   ]

#   create_duration = "60s"

# }

resource "azurerm_route_server_bgp_connection" "ars_to_transit_1_primary" {
  name            = module.mc-transit-1.transit_gateway.gw_name
  route_server_id = azurerm_route_server.ars.id
  peer_asn        = module.mc-transit-1.transit_gateway.local_as_number
  peer_ip         = aviatrix_transit_external_device_conn.transit_1_to_ars.local_lan_ip
}

resource "azurerm_route_server_bgp_connection" "ars_to_transit_1_hagw" {
  name            = module.mc-transit-1.transit_gateway.ha_gw_name
  route_server_id = azurerm_route_server.ars.id
  peer_asn        = module.mc-transit-1.transit_gateway.local_as_number
  peer_ip         = aviatrix_transit_external_device_conn.transit_1_to_ars.backup_local_lan_ip
  depends_on = [
    azurerm_route_server_bgp_connection.ars_to_transit_1_primary
  ]
}