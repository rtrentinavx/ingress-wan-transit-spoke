module "ars-vnet" {
  source              = "Azure/vnet/azurerm"
  version             = "4.1.0"
  resource_group_name = data.azurerm_resource_group.ars-resource-group.name
  use_for_each        = true
  vnet_location       = data.azurerm_resource_group.ars-resource-group.location
  address_space       = var.ars_address_space
  vnet_name           = var.ars_virtual_network_name
  subnet_names        = var.ars_subnet_names
  subnet_prefixes     = var.ars_subnet_prefixes
  tags                = var.tags
}

module "sdwan-vnet" {
  source              = "Azure/vnet/azurerm"
  version             = "4.1.0"
  resource_group_name = data.azurerm_resource_group.sdwan-resource-group.name
  use_for_each        = true
  vnet_location       = data.azurerm_resource_group.sdwan-resource-group.location
  address_space       = var.sdwan_address_space
  vnet_name           = var.sdwan_virtual_network_name
  subnet_names        = var.sdwan_subnet_names
  subnet_prefixes     = var.sdwan_subnet_prefixes
  tags                = var.tags
}

resource "azurerm_virtual_network_peering" "transit_to_ars-virtual_network_peering" {
  name                         = "transit-to-ars"
  resource_group_name          = split(":", data.aviatrix_transit_gateway.transit_gateway.vpc_id)[1]
  virtual_network_name         = split(":", data.aviatrix_transit_gateway.transit_gateway.vpc_id)[0]
  remote_virtual_network_id    = module.ars-vnet.vnet_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = true
}

resource "azurerm_virtual_network_peering" "ars_to_transit-virtual_network_peering" {
  name                         = "ars-to-transit"
  resource_group_name          = data.azurerm_resource_group.ars-resource-group.name
  virtual_network_name         = module.ars-vnet.vnet_name
  remote_virtual_network_id    = data.azurerm_virtual_network.remote_virtual_network.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
}

resource "azurerm_virtual_network_peering" "transit_to_sdwan-virtual_network_peering" {
  name                         = "transit-to-sdwan"
  resource_group_name          = split(":", data.aviatrix_transit_gateway.transit_gateway.vpc_id)[1]
  virtual_network_name         = split(":", data.aviatrix_transit_gateway.transit_gateway.vpc_id)[0]
  remote_virtual_network_id    = module.sdwan-vnet.vnet_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "sdwan-to-transit-virtual_network_peering" {
  name                         = "sdwan-to-transit"
  resource_group_name          = data.azurerm_resource_group.sdwan-resource-group.name
  virtual_network_name         = module.sdwan-vnet.vnet_name
  remote_virtual_network_id    = data.azurerm_virtual_network.remote_virtual_network.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
}

resource "azurerm_virtual_network_peering" "ars_to_sdwan-virtual_network_peering" {
  depends_on = [ module.ars-vnet, module.sdwan-vnet ]
  name                         = "ars-to-sdwan"
  resource_group_name          = data.azurerm_resource_group.ars-resource-group.name
  virtual_network_name         = module.ars-vnet.vnet_name
  remote_virtual_network_id    = module.sdwan-vnet.vnet_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "sdwan-to-ars-virtual_network_peering" {
  depends_on = [ module.ars-vnet, module.sdwan-vnet ]
  name                         = "sdwan-to-ars"
  resource_group_name          = data.azurerm_resource_group.sdwan-resource-group.name
  virtual_network_name         = module.sdwan-vnet.vnet_name
  remote_virtual_network_id    = module.ars-vnet.vnet_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
}

resource "azurerm_network_security_group" "publicnetworknsg" {
  name                = "PublicNetworkSecurityGroup"
  location            = data.azurerm_resource_group.sdwan-resource-group.location
  resource_group_name = data.azurerm_resource_group.sdwan-resource-group.name

  security_rule {
    name                       = "AllowAllInbound"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  tags = var.tags
}

resource "azurerm_network_security_group" "privatenetworknsg" {
  name                = "PrivateNetworkSecurityGroup"
  location            = data.azurerm_resource_group.sdwan-resource-group.location
  resource_group_name = data.azurerm_resource_group.sdwan-resource-group.name

  security_rule {
    name                       = "AllowAllInbound"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  tags = var.tags
}
resource "azurerm_network_security_rule" "outgoing_public" {
  name                        = "AllowAllOutbound"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = data.azurerm_resource_group.sdwan-resource-group.name
  network_security_group_name = azurerm_network_security_group.publicnetworknsg.name
}

resource "azurerm_network_security_rule" "outgoing_private" {
  name                        = "AllowAllOutbound"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = data.azurerm_resource_group.sdwan-resource-group.name
  network_security_group_name = azurerm_network_security_group.privatenetworknsg.name
}

resource "random_id" "randomId" {
  keepers = {
    resource_group = data.azurerm_resource_group.sdwan-resource-group.name
  }
  byte_length = 8
}

resource "azurerm_storage_account" "fgtstorageaccount" {
  name                          = "diag${random_id.randomId.hex}"
  resource_group_name           = data.azurerm_resource_group.sdwan-resource-group.name
  location                      = data.azurerm_resource_group.sdwan-resource-group.location
  account_replication_type      = "LRS"
  account_tier                  = "Standard"
  public_network_access_enabled = false
  tags                          = var.tags
}

resource "aviatrix_transit_external_device_conn" "transit_to_ars" {
  backup_bgp_remote_as_num  = azurerm_route_server.ars.virtual_router_asn
  backup_local_lan_ip       = data.aviatrix_transit_gateway.transit_gateway.ha_bgp_lan_ip_list[0]
  backup_remote_lan_ip      = tolist(azurerm_route_server.ars.virtual_router_ips)[1]
  bgp_local_as_num          = data.aviatrix_transit_gateway.transit_gateway.local_as_number
  bgp_remote_as_num         = azurerm_route_server.ars.virtual_router_asn
  connection_type           = "bgp"
  connection_name           = "transit_to_ars"
  enable_bgp_lan_activemesh = true
  gw_name                   = data.aviatrix_transit_gateway.transit_gateway.gw_name
  ha_enabled                = true
  local_lan_ip              = data.aviatrix_transit_gateway.transit_gateway.bgp_lan_ip_list[0]
  remote_lan_ip             = tolist(azurerm_route_server.ars.virtual_router_ips)[0]
  remote_vpc_name           = "${module.ars-vnet.vnet_name}:${data.azurerm_resource_group.ars-resource-group.name}:${split("/", module.ars-vnet.vnet_id)[2]}"
  vpc_id                    = data.aviatrix_transit_gateway.transit_gateway.vpc_id
  tunnel_protocol           = "LAN"
}

resource "azurerm_route_server_bgp_connection" "ars_to_transit_primary" {
  name            = data.aviatrix_transit_gateway.transit_gateway.gw_name
  route_server_id = azurerm_route_server.ars.id
  peer_asn        = data.aviatrix_transit_gateway.transit_gateway.local_as_number
  peer_ip         = data.aviatrix_transit_gateway.transit_gateway.bgp_lan_ip_list[0]
}

resource "azurerm_route_server_bgp_connection" "ars_to_transit_secondary" {
  name            = data.aviatrix_transit_gateway.transit_gateway.ha_gw_name
  route_server_id = azurerm_route_server.ars.id
  peer_asn        = data.aviatrix_transit_gateway.transit_gateway.local_as_number
  peer_ip         = data.aviatrix_transit_gateway.transit_gateway.ha_bgp_lan_ip_list[0]
}

resource "aviatrix_transit_external_device_conn" "transit_to_forti" {
  depends_on                = [azurerm_virtual_network_peering.ars_to_sdwan-virtual_network_peering]
  backup_bgp_remote_as_num  = var.firewall_as_num
  backup_local_lan_ip       = data.aviatrix_transit_gateway.transit_gateway.ha_bgp_lan_ip_list[1]
  backup_remote_lan_ip      = cidrhost(var.sdwan_subnet_prefixes[1], 5)
  bgp_local_as_num          = data.aviatrix_transit_gateway.transit_gateway.local_as_number
  bgp_remote_as_num         = var.firewall_as_num
  connection_type           = "bgp"
  connection_name           = "transit_to_forti"
  enable_bgp_lan_activemesh = false
  gw_name                   = data.aviatrix_transit_gateway.transit_gateway.gw_name
  ha_enabled                = true
  local_lan_ip              = data.aviatrix_transit_gateway.transit_gateway.bgp_lan_ip_list[1]
  remote_lan_ip             = cidrhost(var.sdwan_subnet_prefixes[1], 4)
  remote_vpc_name           = "${module.sdwan-vnet.vnet_name}:${data.azurerm_resource_group.sdwan-resource-group.name}:${split("/", module.sdwan-vnet.vnet_id)[2]}"
  vpc_id                    = data.aviatrix_transit_gateway.transit_gateway.vpc_id
  tunnel_protocol           = "LAN"
}

resource "azurerm_route_server_bgp_connection" "ars_to_forti_primary" {
  name            = "ars-to-${var.firewall_name[0]}"
  route_server_id = azurerm_route_server.ars.id
  peer_asn        = var.firewall_as_num
  peer_ip         = cidrhost(var.sdwan_subnet_prefixes[1], 4)
}

resource "azurerm_route_server_bgp_connection" "ars_to_forti_secondary" {
  name            = "ars-to-${var.firewall_name[1]}"
  route_server_id = azurerm_route_server.ars.id
  peer_asn        = var.firewall_as_num
  peer_ip         = cidrhost(var.sdwan_subnet_prefixes[1], 5)
}

resource "aviatrix_transit_firenet_policy" "transit_to_forti_transit_firenet_policy" {
  depends_on                   = [aviatrix_transit_external_device_conn.transit_to_forti]
  transit_firenet_gateway_name = var.transit_gateway
  inspected_resource_name      = "SITE2CLOUD:${aviatrix_transit_external_device_conn.transit_to_forti.connection_name}"
}
