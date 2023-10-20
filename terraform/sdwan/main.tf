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

resource "azurerm_route_table" "internal" {
  name                = "InternalRouteTable1"
  location            = data.azurerm_resource_group.resource-group.location
  resource_group_name = data.azurerm_resource_group.resource-group.name
}

resource "azurerm_route" "default" {
  depends_on             = [azurerm_virtual_machine.passivefgtvm]
  name                   = "default"
  resource_group_name    = data.azurerm_resource_group.resource-group.name
  route_table_name       = azurerm_route_table.internal.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = var.activeport3
}

resource "azurerm_subnet_route_table_association" "internalassociate" {
  depends_on     = [azurerm_route_table.internal]
  subnet_id      = module.vnet.vnet_subnets_name_id["privatesubnet"]
  route_table_id = azurerm_route_table.internal.id
}

resource "azurerm_public_ip" "ClusterPublicIP" {
  name                = "ClusterPublicIP"
  location            = data.azurerm_resource_group.resource-group.location
  resource_group_name = data.azurerm_resource_group.resource-group.name
  sku                 = "Standard"
  allocation_method   = "Static"
  tags                = var.tags
}

resource "azurerm_public_ip" "ActiveMGMTIP" {
  name                = "ActiveMGMTIP"
  location            = data.azurerm_resource_group.resource-group.location
  resource_group_name = data.azurerm_resource_group.resource-group.name
  sku                 = "Standard"
  allocation_method   = "Static"
  tags                = var.tags
}

resource "azurerm_public_ip" "PassiveMGMTIP" {
  name                = "PassiveMGMTIP"
  location            = data.azurerm_resource_group.resource-group.location
  resource_group_name = data.azurerm_resource_group.resource-group.name
  sku                 = "Standard"
  allocation_method   = "Static"
  tags                = var.tags
}

resource "azurerm_network_security_group" "publicnetworknsg" {
  name                = "PublicNetworkSecurityGroup"
  location            = data.azurerm_resource_group.resource-group.location
  resource_group_name = data.azurerm_resource_group.resource-group.name

  security_rule {
    name                       = "TCP"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  tags = var.tags
}

resource "azurerm_network_security_group" "privatenetworknsg" {
  name                = "PrivateNetworkSecurityGroup"
  location            = data.azurerm_resource_group.resource-group.location
  resource_group_name = data.azurerm_resource_group.resource-group.name

  security_rule {
    name                       = "All"
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
  name                        = "egress"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = data.azurerm_resource_group.resource-group.name
  network_security_group_name = azurerm_network_security_group.publicnetworknsg.name
}

resource "azurerm_network_security_rule" "outgoing_private" {
  name                        = "egress-private"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = data.azurerm_resource_group.resource-group.name
  network_security_group_name = azurerm_network_security_group.privatenetworknsg.name
}

resource "azurerm_network_interface" "activeport1" {
  name                          = "activeport1"
  location                      = data.azurerm_resource_group.resource-group.location
  resource_group_name           = data.azurerm_resource_group.resource-group.name
  enable_accelerated_networking = var.accelerate == "true" ? true : false

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = module.vnet.vnet_subnets_name_id["hamgmtsubnet"]
    private_ip_address_allocation = "Static"
    private_ip_address            = var.activeport1
    primary                       = true
    public_ip_address_id          = azurerm_public_ip.ActiveMGMTIP.id
  }
  tags = var.tags
}

resource "azurerm_network_interface" "activeport2" {
  name                          = "activeport2"
  location                      = data.azurerm_resource_group.resource-group.location
  resource_group_name           = data.azurerm_resource_group.resource-group.name
  enable_ip_forwarding          = true
  enable_accelerated_networking = var.accelerate == "true" ? true : false

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = module.vnet.vnet_subnets_name_id["publicsubnet"]
    private_ip_address_allocation = "Static"
    private_ip_address            = var.activeport2
    public_ip_address_id          = azurerm_public_ip.ClusterPublicIP.id
  }
  tags = var.tags
}

resource "azurerm_network_interface" "activeport3" {
  name                          = "activeport3"
  location                      = data.azurerm_resource_group.resource-group.location
  resource_group_name           = data.azurerm_resource_group.resource-group.name
  enable_ip_forwarding          = true
  enable_accelerated_networking = var.accelerate == "true" ? true : false

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = module.vnet.vnet_subnets_name_id["privatesubnet"]
    private_ip_address_allocation = "Static"
    private_ip_address            = var.activeport3
  }
  tags = var.tags
}

resource "azurerm_network_interface_security_group_association" "port1nsg" {
  depends_on                = [azurerm_network_interface.activeport1]
  network_interface_id      = azurerm_network_interface.activeport1.id
  network_security_group_id = azurerm_network_security_group.publicnetworknsg.id
}

resource "azurerm_network_interface_security_group_association" "port2nsg" {
  depends_on                = [azurerm_network_interface.activeport2]
  network_interface_id      = azurerm_network_interface.activeport2.id
  network_security_group_id = azurerm_network_security_group.privatenetworknsg.id
}

resource "azurerm_network_interface_security_group_association" "port3nsg" {
  depends_on                = [azurerm_network_interface.activeport3]
  network_interface_id      = azurerm_network_interface.activeport3.id
  network_security_group_id = azurerm_network_security_group.privatenetworknsg.id
}

resource "azurerm_network_interface" "passiveport1" {
  name                          = "passiveport1"
  location                      = data.azurerm_resource_group.resource-group.location
  resource_group_name           = data.azurerm_resource_group.resource-group.name
  enable_accelerated_networking = var.accelerate == "true" ? true : false

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = module.vnet.vnet_subnets_name_id["hamgmtsubnet"]
    private_ip_address_allocation = "Static"
    private_ip_address            = var.passiveport1
    primary                       = true
    public_ip_address_id          = azurerm_public_ip.PassiveMGMTIP.id
  }
  tags = var.tags
}

resource "azurerm_network_interface" "passiveport2" {
  name                          = "passiveport2"
  location                      = data.azurerm_resource_group.resource-group.location
  resource_group_name           = data.azurerm_resource_group.resource-group.name
  enable_ip_forwarding          = true
  enable_accelerated_networking = var.accelerate == "true" ? true : false

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = module.vnet.vnet_subnets_name_id["publicsubnet"]
    private_ip_address_allocation = "Static"
    private_ip_address            = var.passiveport2
  }
  tags = var.tags
}

resource "azurerm_network_interface" "passiveport3" {
  name                          = "passiveport3"
  location                      = data.azurerm_resource_group.resource-group.location
  resource_group_name           = data.azurerm_resource_group.resource-group.name
  enable_ip_forwarding          = true
  enable_accelerated_networking = var.accelerate == "true" ? true : false

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = module.vnet.vnet_subnets_name_id["privatesubnet"]
    private_ip_address_allocation = "Static"
    private_ip_address            = var.passiveport3
  }
  tags = var.tags
}

# Connect the security group to the network interfaces
resource "azurerm_network_interface_security_group_association" "passiveport1nsg" {
  depends_on                = [azurerm_network_interface.passiveport1]
  network_interface_id      = azurerm_network_interface.passiveport1.id
  network_security_group_id = azurerm_network_security_group.publicnetworknsg.id
}

resource "azurerm_network_interface_security_group_association" "passiveport2nsg" {
  depends_on                = [azurerm_network_interface.passiveport2]
  network_interface_id      = azurerm_network_interface.passiveport2.id
  network_security_group_id = azurerm_network_security_group.privatenetworknsg.id
}

resource "azurerm_network_interface_security_group_association" "passiveport3nsg" {
  depends_on                = [azurerm_network_interface.passiveport3]
  network_interface_id      = azurerm_network_interface.passiveport3.id
  network_security_group_id = azurerm_network_security_group.privatenetworknsg.id
}

resource "random_id" "randomId" {
  keepers = {
    resource_group = data.azurerm_resource_group.resource-group.name
  }
  byte_length = 8
}

resource "azurerm_storage_account" "fgtstorageaccount" {
  name                     = "diag${random_id.randomId.hex}"
  resource_group_name      = data.azurerm_resource_group.resource-group.name
  location                 = data.azurerm_resource_group.resource-group.location
  account_replication_type = "LRS"
  account_tier             = "Standard"
  tags                     = var.tags
}

resource "azurerm_virtual_network_peering" "sdwan_to_transit_1" {
  name                         = "transit_1-to-sdwan"
  resource_group_name          = split(":", data.aviatrix_transit_gateway.transit_gateway.vpc_id)[1]
  virtual_network_name         = split(":", data.aviatrix_transit_gateway.transit_gateway.vpc_id)[0]
  remote_virtual_network_id    = module.vnet.vnet_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "transit_1_to_sdwan" {
  name                         = "sdwan-to-transit_1"
  resource_group_name          = data.azurerm_resource_group.resource-group.name
  virtual_network_name         = module.vnet.vnet_name
  remote_virtual_network_id    = data.azurerm_virtual_network.remote_virtual_network.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
}

resource "aviatrix_transit_external_device_conn" "transit_1_to_forti" {
  backup_bgp_remote_as_num  = var.forti_as_num
  backup_local_lan_ip       = data.aviatrix_transit_gateway.transit_gateway.ha_bgp_lan_ip_list[1]
  backup_remote_lan_ip      = var.passiveport3
  bgp_local_as_num          = data.aviatrix_transit_gateway.transit_gateway.local_as_number
  bgp_remote_as_num         = var.forti_as_num
  connection_type           = "bgp"
  connection_name           = "transit_1_to_forti"
  enable_bgp_lan_activemesh = false
  gw_name                   = data.aviatrix_transit_gateway.transit_gateway.gw_name
  ha_enabled                = true
  local_lan_ip              = data.aviatrix_transit_gateway.transit_gateway.bgp_lan_ip_list[1]
  remote_lan_ip             = var.activeport3
  remote_vpc_name           = "${module.vnet.vnet_name}:${data.azurerm_resource_group.resource-group.name}:${split("/", module.vnet.vnet_id)[2]}"
  vpc_id                    = data.aviatrix_transit_gateway.transit_gateway.vpc_id
  tunnel_protocol           = "LAN"
}