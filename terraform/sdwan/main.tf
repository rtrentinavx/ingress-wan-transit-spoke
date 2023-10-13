
resource "azurerm_resource_group" "terraform-azure-resource-group" {
    name = var.resource_group
    location = var.location
    tags = var.tags
    }

resource "azurerm_virtual_network" "terraform-azure-virtual_network" {
  depends_on = [
    azurerm_resource_group.terraform-azure-resource-group
  ]
  name = var.virtual_network_name
  resource_group_name = azurerm_resource_group.terraform-azure-resource-group.name
  address_space = var.address_space
  location = azurerm_resource_group.terraform-azure-resource-group.location
    tags = var.tags
}

resource "azurem_subnet" "terraform-azure-subnet" {
  depends_on = [
    azurerm_virtual_network.terraform-azure-virtual_network
  ]
  for_each = var.subnet
  resource_group_name = azurerm_resource_group.terraform-azure-resource-group.name
  virtual_network_name = azurerm_virtual_network.terraform-azure-virtual_network.name
  name = each.value.name
  address_prefixes = each.value.address_prefixes
      tags = var.tags
}

resource "azurerm_route_table" "route_table" {
  for_each                      = var.subnet
  name                          = "avx-rtb-${azurerm_subnet.terraform-azure-subnet.subnet_name[each.key]}"
  location                      = azurerm_resource_group.terraform-azure-resource-group.location
  resource_group_name           = azurerm_resource_group.terraform-azure-resource-group.name
  disable_bgp_route_propagation = true

  route {
    name           = "avx-rt-internet"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "None"
  }
      tags = var.tags
}

resource "azurerm_subnet_route_table_association" "subnet_route_table_association" {
  depends_on = [
    azurerm_route_table.route_table
  ]
  for_each       = var.subnet
  route_table_id = azurerm_route_table.route_table[each.key].id
  subnet_id      = azurem_subnet.terraform-azure-subnet.subnet_id[each.key]
}

resource "azurerm_route_table" "internal" {
  name                = "InternalRouteTable1"
  location            = azurerm_resource_group.terraform-azure-resource-group.location
  resource_group_name = azurerm_resource_group.terraform-azure-resource-group.name
}

resource "azurerm_route" "default" {
  depends_on             = [azurerm_virtual_machine.passivefgtvm]
  name                   = "default"
  resource_group_name    = azurerm_resource_group.terraform-azure-resource-group.name
  route_table_name       = azurerm_route_table.internal.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = var.activeport3
}

resource "azurerm_subnet_route_table_association" "internalassociate" {
  depends_on     = [azurerm_route_table.internal]
  subnet_id      = azurerm_subnet.privatesubnet.id
  route_table_id = azurerm_route_table.internal.id
}



resource "azurerm_public_ip" "ClusterPublicIP" {
  name                = "ClusterPublicIP"
  location            = var.location
  resource_group_name = azurerm_resource_group.terraform-azure-resource-group.name
  sku                 = "Standard"
  allocation_method   = "Static"
  tags = var.tags
}

resource "azurerm_public_ip" "ActiveMGMTIP" {
  name                = "ActiveMGMTIP"
  location            = var.location
  resource_group_name = azurerm_resource_group.terraform-azure-resource-group.name
  sku                 = "Standard"
  allocation_method   = "Static"
  tags = var.tags
}

resource "azurerm_public_ip" "PassiveMGMTIP" {
  name                = "PassiveMGMTIP"
  location            = var.location
  resource_group_name = azurerm_resource_group.terraform-azure-resource-group.name
  sku                 = "Standard"
  allocation_method   = "Static"
  tags = var.tags
}

resource "azurerm_network_security_group" "publicnetworknsg" {
  name                = "PublicNetworkSecurityGroup"
  location            = var.location
  resource_group_name = azurerm_resource_group.terraform-azure-resource-group.name

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
  location            = var.location
  resource_group_name = azurerm_resource_group.terraform-azure-resource-group.name

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
  resource_group_name         = azurerm_resource_group.terraform-azure-resource-group.name
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
  resource_group_name         = azurerm_resource_group.terraform-azure-resource-group.name
  network_security_group_name = azurerm_network_security_group.privatenetworknsg.name
}

resource "azurerm_network_interface" "activeport1" {
  name                          = "activeport1"
  location                      = var.location
  resource_group_name           = azurerm_resource_group.terraform-azure-resource-group.name
  enable_accelerated_networking = var.accelerate == "true" ? true : false

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.hamgmtsubnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.activeport1
    primary                       = true
    public_ip_address_id          = azurerm_public_ip.ActiveMGMTIP.id
  }
  tags = var.tags
}

resource "azurerm_network_interface" "activeport2" {
  name                          = "activeport2"
  location                      = var.location
  resource_group_name           = azurerm_resource_group.terraform-azure-resource-group.name
  enable_ip_forwarding          = true
  enable_accelerated_networking = var.accelerate == "true" ? true : false

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.publicsubnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.activeport2
    public_ip_address_id          = azurerm_public_ip.ClusterPublicIP.id
  }

  tags = {
    environment = "Terraform Demo"
  }
}

resource "azurerm_network_interface" "activeport3" {
  name                          = "activeport3"
  location                      = var.location
  resource_group_name           = azurerm_resource_group.terraform-azure-resource-group.name
  enable_ip_forwarding          = true
  enable_accelerated_networking = var.accelerate == "true" ? true : false

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.privatesubnet.id
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
  location                      = var.location
  resource_group_name           = azurerm_resource_group.terraform-azure-resource-group.name
  enable_accelerated_networking = var.accelerate == "true" ? true : false

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.hamgmtsubnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.passiveport1
    primary                       = true
    public_ip_address_id          = azurerm_public_ip.PassiveMGMTIP.id
  }
  tags = var.tags
}

resource "azurerm_network_interface" "passiveport2" {
  name                          = "passiveport2"
  location                      = var.location
  resource_group_name           = azurerm_resource_group.terraform-azure-resource-group.name
  enable_ip_forwarding          = true
  enable_accelerated_networking = var.accelerate == "true" ? true : false

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.publicsubnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.passiveport2
  }
  tags = var.tags
}

resource "azurerm_network_interface" "passiveport3" {
  name                          = "passiveport3"
  location                      = var.location
  resource_group_name           = azurerm_resource_group.terraform-azure-resource-group.name
  enable_ip_forwarding          = true
  enable_accelerated_networking = var.accelerate == "true" ? true : false

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.privatesubnet.id
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
