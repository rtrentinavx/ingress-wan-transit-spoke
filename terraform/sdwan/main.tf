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

resource "azurerm_public_ip" "firewall-1-MGMTIP" {
  count               = var.management == "public" ? 1 : 0
  name                = "firewall-1MGMTIP"
  location            = data.azurerm_resource_group.resource-group.location
  resource_group_name = data.azurerm_resource_group.resource-group.name
  allocation_method   = "Static"
  sku                 = "Standard"
  sku_tier            = "Regional"
  tags                = var.tags
}

resource "azurerm_public_ip" "firewall-2-MGMTIP" {
  count               = var.management == "public" ? 1 : 0
  name                = "firewall-2-MGMTIP"
  location            = data.azurerm_resource_group.resource-group.location
  resource_group_name = data.azurerm_resource_group.resource-group.name
  allocation_method   = "Static"
  sku                 = "Standard"
  sku_tier            = "Regional"
  tags                = var.tags
}

resource "azurerm_network_security_group" "publicnetworknsg" {
  name                = "PublicNetworkSecurityGroup"
  location            = data.azurerm_resource_group.resource-group.location
  resource_group_name = data.azurerm_resource_group.resource-group.name

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
  location            = data.azurerm_resource_group.resource-group.location
  resource_group_name = data.azurerm_resource_group.resource-group.name

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
  resource_group_name         = data.azurerm_resource_group.resource-group.name
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
  resource_group_name         = data.azurerm_resource_group.resource-group.name
  network_security_group_name = azurerm_network_security_group.privatenetworknsg.name
}

resource "azurerm_network_interface" "firewall-1-port1" {
  name                          = "firewall-1-port1"
  location                      = data.azurerm_resource_group.resource-group.location
  resource_group_name           = data.azurerm_resource_group.resource-group.name
  enable_accelerated_networking = var.accelerate == "true" ? true : false
  enable_ip_forwarding = true 

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = module.vnet.vnet_subnets_name_id["publicsubnet"]
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost(var.subnet_prefixes[0], 4)
    primary                       = true
    public_ip_address_id          = var.management == "public" ? azurerm_public_ip.firewall-1-MGMTIP[0].id : null

  }
  tags = var.tags
}

resource "azurerm_network_interface" "firewall-1-port2" {
  name                          = "firewall-1-port2"
  location                      = data.azurerm_resource_group.resource-group.location
  resource_group_name           = data.azurerm_resource_group.resource-group.name
  enable_ip_forwarding          = true
  enable_accelerated_networking = var.accelerate == "true" ? true : false

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = module.vnet.vnet_subnets_name_id["privatesubnet"]
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost(var.subnet_prefixes[1], 4)
  }
  tags = var.tags
}

resource "azurerm_network_interface" "firewall-1-port3" {
  name                          = "firewall-1-port3"
  location                      = data.azurerm_resource_group.resource-group.location
  resource_group_name           = data.azurerm_resource_group.resource-group.name
  enable_ip_forwarding          = true
  enable_accelerated_networking = var.accelerate == "true" ? true : false

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = module.vnet.vnet_subnets_name_id["hasubnet"]
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost(var.subnet_prefixes[2], 4)
  }
  tags = var.tags
}

resource "azurerm_network_interface_security_group_association" "firewall-1-port1nsg" {
  depends_on                = [azurerm_network_interface.firewall-1-port1]
  network_interface_id      = azurerm_network_interface.firewall-1-port1.id
  network_security_group_id = azurerm_network_security_group.publicnetworknsg.id
}

resource "azurerm_network_interface_security_group_association" "firewall-1-port2nsg" {
  depends_on                = [azurerm_network_interface.firewall-1-port2]
  network_interface_id      = azurerm_network_interface.firewall-1-port2.id
  network_security_group_id = azurerm_network_security_group.privatenetworknsg.id
}

resource "azurerm_network_interface_security_group_association" "firewall-1-port3nsg" {
  depends_on                = [azurerm_network_interface.firewall-1-port3]
  network_interface_id      = azurerm_network_interface.firewall-1-port3.id
  network_security_group_id = azurerm_network_security_group.privatenetworknsg.id
}

resource "azurerm_network_interface" "firewall-2-port1" {
  name                          = "firewall-2-port1"
  location                      = data.azurerm_resource_group.resource-group.location
  resource_group_name           = data.azurerm_resource_group.resource-group.name
  enable_accelerated_networking = var.accelerate == "true" ? true : false
  enable_ip_forwarding = true 

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = module.vnet.vnet_subnets_name_id["publicsubnet"]
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost(var.subnet_prefixes[0], 5)
    primary                       = true
    public_ip_address_id          = var.management == "public" ? azurerm_public_ip.firewall-2-MGMTIP[0].id : null
  }
  tags = var.tags
}

resource "azurerm_network_interface" "firewall-2-port2" {
  name                          = "firewall-2-port2"
  location                      = data.azurerm_resource_group.resource-group.location
  resource_group_name           = data.azurerm_resource_group.resource-group.name
  enable_ip_forwarding          = true
  enable_accelerated_networking = var.accelerate == "true" ? true : false

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = module.vnet.vnet_subnets_name_id["privatesubnet"]
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost(var.subnet_prefixes[1], 5)
  }
  tags = var.tags
}

resource "azurerm_network_interface" "firewall-2-port3" {
  name                          = "firewall-2-port3"
  location                      = data.azurerm_resource_group.resource-group.location
  resource_group_name           = data.azurerm_resource_group.resource-group.name
  enable_ip_forwarding          = true
  enable_accelerated_networking = var.accelerate == "true" ? true : false

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = module.vnet.vnet_subnets_name_id["hasubnet"]
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost(var.subnet_prefixes[2], 5)
  }
  tags = var.tags
}

resource "azurerm_network_interface_security_group_association" "firewall-2-port1nsg" {
  depends_on                = [azurerm_network_interface.firewall-2-port1]
  network_interface_id      = azurerm_network_interface.firewall-2-port1.id
  network_security_group_id = azurerm_network_security_group.publicnetworknsg.id
}

resource "azurerm_network_interface_security_group_association" "firewall-2-port2nsg" {
  depends_on                = [azurerm_network_interface.firewall-2-port2]
  network_interface_id      = azurerm_network_interface.firewall-2-port2.id
  network_security_group_id = azurerm_network_security_group.privatenetworknsg.id
}

resource "azurerm_network_interface_security_group_association" "firewall-2-port3nsg" {
  depends_on                = [azurerm_network_interface.firewall-2-port3]
  network_interface_id      = azurerm_network_interface.firewall-2-port3.id
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

resource "azurerm_virtual_network_peering" "transit_1_to_sdwan" {
  name                         = "transit_1-to-sdwan"
  resource_group_name          = split(":", data.aviatrix_transit_gateway.transit_gateway.vpc_id)[1]
  virtual_network_name         = split(":", data.aviatrix_transit_gateway.transit_gateway.vpc_id)[0]
  remote_virtual_network_id    = module.vnet.vnet_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "sdwan-to-transit_1" {
  name                         = "sdwan-to-transit_1"
  resource_group_name          = data.azurerm_resource_group.resource-group.name
  virtual_network_name         = module.vnet.vnet_name
  remote_virtual_network_id    = data.azurerm_virtual_network.remote_virtual_network.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
}

resource "aviatrix_transit_external_device_conn" "transit_1_to_forti" {
  depends_on                = [azurerm_virtual_network_peering.transit_1_to_sdwan, azurerm_virtual_network_peering.sdwan-to-transit_1]
  backup_bgp_remote_as_num  = var.firewall_as_num
  backup_local_lan_ip       = data.aviatrix_transit_gateway.transit_gateway.ha_bgp_lan_ip_list[1]
  backup_remote_lan_ip      = cidrhost(var.subnet_prefixes[1], 5)
  bgp_local_as_num          = data.aviatrix_transit_gateway.transit_gateway.local_as_number
  bgp_remote_as_num         = var.firewall_as_num
  connection_type           = "bgp"
  connection_name           = "transit_1_to_forti"
  enable_bgp_lan_activemesh = false
  gw_name                   = data.aviatrix_transit_gateway.transit_gateway.gw_name
  ha_enabled                = true
  local_lan_ip              = data.aviatrix_transit_gateway.transit_gateway.bgp_lan_ip_list[1]
  remote_lan_ip             = cidrhost(var.subnet_prefixes[1], 4)
  remote_vpc_name           = "${module.vnet.vnet_name}:${data.azurerm_resource_group.resource-group.name}:${split("/", module.vnet.vnet_id)[2]}"
  vpc_id                    = data.aviatrix_transit_gateway.transit_gateway.vpc_id
  tunnel_protocol           = "LAN"
}

resource "aviatrix_transit_firenet_policy" "transit_1_to_forti_transit_firenet_policy" {
  depends_on = [ aviatrix_transit_external_device_conn.transit_1_to_forti ]
  transit_firenet_gateway_name = var.transit_gateway
  inspected_resource_name      = "SITE2CLOUD:${aviatrix_transit_external_device_conn.transit_1_to_forti.connection_name}"
}