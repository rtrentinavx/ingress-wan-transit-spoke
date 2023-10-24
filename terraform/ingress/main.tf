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

resource "azurerm_public_ip" "pip-appgw" {
  name                = "pip-${var.appgw_name}"
  resource_group_name = data.azurerm_resource_group.resource-group.name
  location            = data.azurerm_resource_group.resource-group.location
  allocation_method   = "Static"
  sku                 = "Standard"
  sku_tier            = "Regional"
  tags                = var.tags
}

resource "azurerm_application_gateway" "appgw" {
  name                = var.appgw_name
  resource_group_name = data.azurerm_resource_group.resource-group.name
  location            = data.azurerm_resource_group.resource-group.location

  sku {
    name     = var.appgw_sku
    tier     = var.appgw_sku
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "ip-config-${var.appgw_name}"
    subnet_id = module.vnet.vnet_subnets_name_id["frontend"]
  }

  frontend_port {
    name = "fe-port-${var.appgw_name}"
    port = var.fe-port
  }

  frontend_ip_configuration {
    name                 = "feip-${var.appgw_name}"
    public_ip_address_id = azurerm_public_ip.pip-appgw.id
  }

  backend_address_pool {
    name         = "pool-${var.appgw_name}"
    ip_addresses = ["${cidrhost(var.subnet_prefixes["4"], 4)}", "${cidrhost(var.subnet_prefixes["4"], 5)}"]
  }

  probe {
    name                                      = "probe-${var.appgw_name}"
    interval                                  = var.probe-interval
    timeout                                   = (3 * var.probe-interval)
    protocol                                  = var.be-protocol
    port                                      = var.be-port
    path                                      = var.be-path
    unhealthy_threshold                       = 3
    pick_host_name_from_backend_http_settings = true
  }

  backend_http_settings {
    name                                = "be-${var.appgw_name}"
    cookie_based_affinity               = "Disabled"
    path                                = var.be-path
    port                                = var.be-port
    protocol                            = var.be-protocol
    request_timeout                     = 60
    probe_name                          = "probe-${var.appgw_name}"
    pick_host_name_from_backend_address = true
  }

  # ssl_certificate {
  #   name                = "cert-${var.appgw_name}"
  #   key_vault_secret_id = data.azurerm_key_vault_secret.secret-appgw-cert.value
  # }

  http_listener {
    name                           = "listener-${var.appgw_name}"
    frontend_ip_configuration_name = "feip-${var.appgw_name}"
    frontend_port_name             = "fe-port-${var.appgw_name}"
    protocol                       = var.fe-protocol
    # ssl_certificate_name           = "cert-${var.appgw_name}"
  }

  request_routing_rule {
    name                       = "rule-${var.appgw_name}"
    priority                   = 10
    rule_type                  = "Basic"
    http_listener_name         = "listener-${var.appgw_name}"
    backend_address_pool_name  = "pool-${var.appgw_name}"
    backend_http_settings_name = "be-${var.appgw_name}"
  }
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
    subnet_id                     = module.vnet.vnet_subnets_name_id["mgmtsubnet"]
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost(var.subnet_prefixes[3], 4)
    primary                       = true
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
    private_ip_address            = cidrhost(var.subnet_prefixes[4], 4)
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
    private_ip_address            = cidrhost(var.subnet_prefixes[5], 4)
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
    subnet_id                     = module.vnet.vnet_subnets_name_id["mgmtsubnet"]
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost(var.subnet_prefixes[3], 5)
    primary                       = true
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
    private_ip_address            = cidrhost(var.subnet_prefixes[4], 5)
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
    private_ip_address            = cidrhost(var.subnet_prefixes[6], 5)
  }
  tags = var.tags
}

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

module "regions" {
  source       = "claranet/regions/azurerm"
  version      = "7.0.0"
  azure_region = data.azurerm_resource_group.resource-group.location
}

module "mc-spoke" {
  depends_on = [ azurerm_virtual_machine.activefgtvm, azurerm_virtual_machine.passivefgtvm ]
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

