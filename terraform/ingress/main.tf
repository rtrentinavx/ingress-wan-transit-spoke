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
  name                = "firewall-1-MGMTIP"
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
    private_ip_address            = cidrhost(var.subnet_prefixes[3], 4)
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
    subnet_id                     = module.vnet.vnet_subnets_name_id["privatesubnet-1"]
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost(var.subnet_prefixes[4], 4)
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
    private_ip_address            = cidrhost(var.subnet_prefixes[3], 5)
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
    subnet_id                     = module.vnet.vnet_subnets_name_id["privatesubnet-2"]
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost(var.subnet_prefixes[5], 5)
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

module "regions" {
  source       = "claranet/regions/azurerm"
  version      = "7.0.0"
  azure_region = data.azurerm_resource_group.resource-group.location
}

module "mc-spoke" {
  depends_on             = [azurerm_virtual_machine.firewall-1, azurerm_virtual_machine.firewall-2]
  source                 = "terraform-aviatrix-modules/mc-spoke/aviatrix"
  version                = "1.6.5"
  cloud                  = "Azure"
  name                   = var.virtual_network_name
  region                 = module.regions.location
  cidr                   = element(var.address_space, 0)
  account                = data.azurerm_subscription.current.display_name
  transit_gw             = var.transit_gateway
  enable_max_performance = var.enable_max_performance != false ? var.enable_max_performance : null
  insane_mode            = var.insane_mode
  gw_name                = var.gw_name
  gw_subnet              = var.subnet_prefixes[0]
  hagw_subnet            = var.subnet_prefixes[1]
  inspection             = true
  instance_size          = var.instance_size
  tags                   = var.tags
  use_existing_vpc       = true
  vpc_id                 = "${module.vnet.vnet_name}:${data.azurerm_resource_group.resource-group.name}:${module.vnet.vnet_guid}"
}

