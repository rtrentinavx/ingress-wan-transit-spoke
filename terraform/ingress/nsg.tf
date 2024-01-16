resource "azurerm_network_security_group" "publicnetworknsg" {
  name                = "PublicNetworkSecurityGroup"
  location            = data.azurerm_resource_group.resource-group.location
  resource_group_name = data.azurerm_resource_group.resource-group.name
  tags                = var.tags
}

resource "azurerm_network_security_group" "privatenetworknsg" {
  name                = "PrivateNetworkSecurityGroup"
  location            = data.azurerm_resource_group.resource-group.location
  resource_group_name = data.azurerm_resource_group.resource-group.name
  tags                = var.tags
}

resource "azurerm_network_security_rule" "inbound_public" {
  access                                     = "Allow"
  destination_address_prefix                 = "*"
  destination_application_security_group_ids = []
  destination_port_range                     = "*"
  direction                                  = "Inbound"
  name                                       = "AllowAllInbound"
  priority                                   = 1001
  protocol                                   = "*"
  source_address_prefix                      = "*"
  source_application_security_group_ids      = []
  source_port_range                          = "*"
  resource_group_name                        = data.azurerm_resource_group.resource-group.name
  network_security_group_name                = azurerm_network_security_group.publicnetworknsg.name
}

resource "azurerm_network_security_rule" "outgoing_public" {
  access                                     = "Allow"
  destination_address_prefix                 = "*"
  destination_application_security_group_ids = []
  destination_port_range                     = "*"
  direction                                  = "Outbound"
  name                                       = "AllowAllOutbound"
  priority                                   = 1001
  protocol                                   = "*"
  source_address_prefix                      = "*"
  source_application_security_group_ids      = []
  source_port_range                          = "*"
  resource_group_name                        = data.azurerm_resource_group.resource-group.name
  network_security_group_name                = azurerm_network_security_group.publicnetworknsg.name
}

resource "azurerm_network_security_rule" "inbound_private" {
  access                                     = "Allow"
  destination_address_prefix                 = "*"
  destination_application_security_group_ids = []
  destination_port_range                     = "*"
  direction                                  = "Inbound"
  name                                       = "AllowAllInbound"
  priority                                   = 1001
  protocol                                   = "*"
  source_address_prefix                      = "*"
  source_application_security_group_ids      = []
  source_port_range                          = "*"
  resource_group_name                        = data.azurerm_resource_group.resource-group.name
  network_security_group_name                = azurerm_network_security_group.privatenetworknsg.name
}

resource "azurerm_network_security_rule" "outgoing_private" {
  access                                     = "Allow"
  destination_address_prefix                 = "*"
  destination_application_security_group_ids = []
  destination_port_range                     = "*"
  direction                                  = "Outbound"
  name                                       = "AllowAllOutbound"
  priority                                   = 1001
  protocol                                   = "*"
  source_address_prefix                      = "*"
  source_application_security_group_ids      = []
  source_port_range                          = "*"
  resource_group_name                        = data.azurerm_resource_group.resource-group.name
  network_security_group_name                = azurerm_network_security_group.privatenetworknsg.name
}