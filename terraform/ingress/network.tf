resource "azurerm_network_security_group" "mgmtnetworknsg" {
  name                = "MgmtNetworkSecurityGroup"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

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
}

resource "azurerm_network_security_group" "publicnetworknsg" {
  name                = "PublicNetworkSecurityGroup"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

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
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

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

resource "azurerm_network_security_rule" "outgoing_mgmt" {
  name                        = "egress-mgmt"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.resource_group.name
  network_security_group_name = azurerm_network_security_group.mgmtnetworknsg.name
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
  resource_group_name         = azurerm_resource_group.resource_group.name
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
  resource_group_name         = azurerm_resource_group.resource_group.name
  network_security_group_name = azurerm_network_security_group.privatenetworknsg.name
}

resource "azurerm_network_interface" "fgtport1" {
  name                = "fgtport1"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = module.vnet.vnet_subnets_name_id[0]
    private_ip_address_allocation = "Dynamic"
    primary                       = true
    public_ip_address_id          = azurerm_public_ip.FGTPublicIp.id
  }
  tags = var.tags
}

resource "azurerm_network_interface" "fgtport2" {
  name                 = "fgtport2"
  location             = azurerm_resource_group.resource_group.location
  resource_group_name  = azurerm_resource_group.resource_group.name
  enable_ip_forwarding = true

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = module.vnet.vnet_subnets_name_id[1]
    private_ip_address_allocation = "Dynamic"
  }
  tags = var.tags
}

resource "azurerm_network_interface" "fgtport3" {
  name                 = "fgtport3"
  location             = azurerm_resource_group.resource_group.location
  resource_group_name  = azurerm_resource_group.resource_group.name
  enable_ip_forwarding = true

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = module.vnet.vnet_subnets_name_id[2]
    private_ip_address_allocation = "Dynamic"
  }
  tags = var.tags
}

resource "azurerm_network_interface_security_group_association" "port1nsg" {
  depends_on                = [azurerm_network_interface.fgtport1]
  network_interface_id      = azurerm_network_interface.fgtport1.id
  network_security_group_id = azurerm_network_security_group.mgmtnetworknsg.id
}


resource "azurerm_network_interface_security_group_association" "port2nsg" {
  depends_on                = [azurerm_network_interface.fgtport2]
  network_interface_id      = azurerm_network_interface.fgtport2.id
  network_security_group_id = azurerm_network_security_group.publicnetworknsg.id
}

resource "azurerm_network_interface_security_group_association" "port3nsg" {
  depends_on                = [azurerm_network_interface.fgtport3]
  network_interface_id      = azurerm_network_interface.fgtport3.id
  network_security_group_id = azurerm_network_security_group.privatenetworknsg.id
}

