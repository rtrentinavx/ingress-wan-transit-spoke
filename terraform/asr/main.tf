module "vnet" {
  source              = "Azure/vnet/azurerm"
  version             = "4.1.0"
  resource_group_name = data.azurerm_resource_group.resource-group.name
  use_for_each        = true
  vnet_location       = data.azurerm_resource_group.resource-group.location
  address_space       = var.address_space
  vnet_name           = var.virtual_network_name
  subnet_names        = var.subnet_names
  subnet_prefixes     = var.subnet_prefixes
  tags                = var.tags
}

resource "azurerm_public_ip" "pip-ars" {
  name                = "pip-asr-${var.virtual_network_name}"
  location            = data.azurerm_resource_group.resource-group.location
  resource_group_name = data.azurerm_resource_group.resource-group.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_route_server" "ars" {
  name                             = "ars-${var.virtual_network_name}"
  location                         = data.azurerm_resource_group.resource-group.location
  resource_group_name              = data.azurerm_resource_group.resource-group.name
  sku                              = "Standard"
  public_ip_address_id             = azurerm_public_ip.pip-ars.id
  subnet_id                        = module.vnet.vnet_subnets_name_id["RouteServerSubnet"]
  branch_to_branch_traffic_enabled = true
  tags                             = var.tags
}

resource "azurerm_public_ip" "pip-vng-1" {
  name                = "pip-vng-1-${var.virtual_network_name}"
  location            = data.azurerm_resource_group.resource-group.location
  resource_group_name = data.azurerm_resource_group.resource-group.name
  allocation_method   = "Dynamic"
}

resource "azurerm_public_ip" "pip-vng-2" {
  name                = "pip-vng-2-${var.virtual_network_name}"
  location            = data.azurerm_resource_group.resource-group.location
  resource_group_name = data.azurerm_resource_group.resource-group.name
  allocation_method   = "Dynamic"
}

resource "azurerm_virtual_network_gateway" "vng" {
  name                = var.vng_name
  location            = data.azurerm_resource_group.resource-group.location
  resource_group_name = data.azurerm_resource_group.resource-group.name

  type     = var.vpn_gateway_type
  vpn_type = var.vpn_type

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
    public_ip_address_id          = azurerm_public_ip.pip-vng-1.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = module.vnet.vnet_subnets_name_id["GatewaySubnet"]
  }

  ip_configuration {
    name                          = "vnetGatewayConfig2"
    public_ip_address_id          = azurerm_public_ip.pip-vng-2.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = module.vnet.vnet_subnets_name_id["GatewaySubnet"]
  }
}

resource "azurerm_virtual_network_peering" "transit_1_to_vng" {
  name                         = "transit-to-vng"
  resource_group_name          = split(":",data.aviatrix_transit_gateway.transit_gateway.vpc_id)[1]
  virtual_network_name         = split(":", data.aviatrix_transit_gateway.transit_gateway.vpc_id)[0]
  remote_virtual_network_id    = module.vnet.vnet_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = true
}

resource "azurerm_virtual_network_peering" "vng_to_transit_1" {
  name                         = "vng-to-spoke"
  resource_group_name          = data.azurerm_resource_group.resource-group.name
  virtual_network_name         = module.vnet.vnet_name
  remote_virtual_network_id    = data.azurerm_virtual_network.remote_virtual_network.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
}

resource "aviatrix_transit_external_device_conn" "transit_1_to_ars" {
  vpc_id            = data.aviatrix_transit_gateway.transit_gateway.vpc_id
  connection_name   = "transit_1_to_ars"
  gw_name           = data.aviatrix_transit_gateway.transit_gateway.gw_name
  connection_type   = "bgp"
  tunnel_protocol   = "LAN"
  bgp_local_as_num  = data.aviatrix_transit_gateway.transit_gateway.local_as_number
  bgp_remote_as_num = azurerm_route_server.ars.virtual_router_asn
  remote_lan_ip     = tolist(azurerm_route_server.ars.virtual_router_ips)[0]
  local_lan_ip      = data.aviatrix_transit_gateway.transit_gateway.bgp_lan_ip_list[0]
  remote_vpc_name = "${module.vnet.vnet_name}:${data.azurerm_resource_group.resource-group.name}:${split("/",module.vnet.vnet_id)[1]}"
  }


# resource "aviatrix_transit_external_device_conn" "ex-conn" {
#   vpc_id            = aviatrix_transit_gateway.transit-gateway.vpc_id
#   connection_name   = "my_conn"
#   gw_name           = aviatrix_transit_gateway.transit-gateway.gw_name
#   connection_type   = "bgp"
#   tunnel_protocol   = "LAN"
#   bgp_local_as_num  = "123"
#   bgp_remote_as_num = "345"
#   remote_lan_ip     = "172.12.13.14"
#   local_lan_ip      = "172.12.13.15"
#   remote_vpc_name   = "vnet-name:resource-group-name:subscription-id"
# }

# resource "azurerm_route_server_bgp_connection" "ars_to_transit_1_primary" {
#   name            = var.transit_gateway
#   route_server_id = azurerm_route_server.ars.id
#   peer_asn        = data.aviatrix_transit_gateway.transit_gateway.local_as_number
#   peer_ip         = data.aviatrix_transit_gateway.transit_gateway.
# }

# resource "azurerm_route_server_bgp_connection" "ars_to_transit_1_hagw" {
#   name            = module.mc-transit-1.transit_gateway.ha_gw_name
#   route_server_id = azurerm_route_server.ars.id
#   peer_asn        = module.mc-transit-1.transit_gateway.local_as_number
#   peer_ip         = aviatrix_transit_external_device_conn.transit_1_to_ars.backup_local_lan_ip
# }