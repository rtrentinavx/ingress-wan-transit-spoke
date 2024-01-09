resource "azurerm_public_ip" "firewall-1-MGMTIP" {
  count               = var.management == "public" ? 1 : 0
  name                = "firewall-1MGMTIP"
  location            = data.azurerm_resource_group.sdwan-resource-group.location
  resource_group_name = data.azurerm_resource_group.sdwan-resource-group.name
  allocation_method   = "Static"
  sku                 = "Standard"
  sku_tier            = "Regional"
  tags                = var.tags
}

resource "azurerm_network_interface" "firewall-1-port1" {
  name                          = "firewall-1-port1"
  location                      = data.azurerm_resource_group.sdwan-resource-group.location
  resource_group_name           = data.azurerm_resource_group.sdwan-resource-group.name
  enable_accelerated_networking = var.accelerate == "true" ? true : false
  enable_ip_forwarding          = true

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = module.sdwan-vnet.vnet_subnets_name_id["test-sdwan-untrust-snet01"]
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost(var.sdwan_subnet_prefixes[0], 5)
    primary                       = true
  }
  tags = var.tags
}

resource "azurerm_network_interface" "firewall-1-port2" {
  name                          = "firewall-1-port2"
  location                      = data.azurerm_resource_group.sdwan-resource-group.location
  resource_group_name           = data.azurerm_resource_group.sdwan-resource-group.name
  enable_ip_forwarding          = true
  enable_accelerated_networking = var.accelerate == "true" ? true : false

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = module.sdwan-vnet.vnet_subnets_name_id["test-sdwan-trust-snet01"]
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost(var.sdwan_subnet_prefixes[1], 5)
  }
  tags = var.tags
}

resource "azurerm_network_interface" "firewall-1-port3" {
  name                          = "firewall-1-port3"
  location                      = data.azurerm_resource_group.sdwan-resource-group.location
  resource_group_name           = data.azurerm_resource_group.sdwan-resource-group.name
  enable_ip_forwarding          = true
  enable_accelerated_networking = var.accelerate == "true" ? true : false

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = module.sdwan-vnet.vnet_subnets_name_id["test-sdwan-ha-snet01"]
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost(var.sdwan_subnet_prefixes[2], 5)
  }
  tags = var.tags
}

resource "azurerm_network_interface" "firewall-1-port4" {
  name                          = "firewall-1-port4"
  location                      = data.azurerm_resource_group.sdwan-resource-group.location
  resource_group_name           = data.azurerm_resource_group.sdwan-resource-group.name
  enable_ip_forwarding          = true
  enable_accelerated_networking = var.accelerate == "true" ? true : false

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = module.sdwan-vnet.vnet_subnets_name_id["test-sdwan-mgmt-snet01"]
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost(var.sdwan_subnet_prefixes[3], 5)
    public_ip_address_id          = var.management == "public" ? azurerm_public_ip.firewall-1-MGMTIP[0].id : null
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

resource "azurerm_network_interface_security_group_association" "firewall-1-port4nsg" {
  depends_on                = [azurerm_network_interface.firewall-1-port4]
  network_interface_id      = azurerm_network_interface.firewall-1-port4.id
  network_security_group_id = azurerm_network_security_group.publicnetworknsg.id
}

resource "azurerm_virtual_machine" "firewall-1" {
  name                         = var.firewall_name[0]
  location                     = data.azurerm_resource_group.sdwan-resource-group.location
  resource_group_name          = data.azurerm_resource_group.sdwan-resource-group.name
  network_interface_ids        = [azurerm_network_interface.firewall-1-port1.id, azurerm_network_interface.firewall-1-port2.id, azurerm_network_interface.firewall-1-port3.id, azurerm_network_interface.firewall-1-port4.id]
  primary_network_interface_id = azurerm_network_interface.firewall-1-port1.id
  vm_size                      = var.firewall_instance_size
  # zones                            = [var.zone1]
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = var.publisher
    offer     = var.fgtoffer
    sku       = var.firewall_image == "byol" ? var.fgtsku["byol"] : var.fgtsku["payg"]
    version   = var.firewall_image_version
    id        = null
  }

  plan {
    name      = var.firewall_image == "byol" ? var.fgtsku["byol"] : var.fgtsku["payg"]
    publisher = var.publisher
    product   = var.fgtoffer
  }

  storage_os_disk {
    name              = "${var.firewall_name[0]}osDisk"
    caching           = "ReadWrite"
    managed_disk_type = "Standard_LRS"
    create_option     = "FromImage"
  }

  # Log data disks
  storage_data_disk {
    name              = "${var.firewall_name[0]}datadisk"
    managed_disk_type = "Standard_LRS"
    create_option     = "Empty"
    lun               = 0
    disk_size_gb      = "30"

  }

  os_profile {
    computer_name  = var.firewall_name[0]
    admin_username = data.azurerm_key_vault_secret.secret-firewall-username.value
    admin_password = data.azurerm_key_vault_secret.secret-firewall-password.value
    custom_data = templatefile("${path.module}/config-firewall-1.conf", {
      type                   = var.firewall_image
      license_file           = var.license
      firewall_name          = var.firewall_name[0]
      port1_ip               = cidrhost(var.sdwan_subnet_prefixes[0], 5)
      port1_mask             = cidrnetmask(var.sdwan_subnet_prefixes[0])
      port2_ip               = cidrhost(var.sdwan_subnet_prefixes[1], 5)
      port2_mask             = cidrnetmask(var.sdwan_subnet_prefixes[1])
      port3_ip               = cidrhost(var.sdwan_subnet_prefixes[2], 5)
      port3_mask             = cidrnetmask(var.sdwan_subnet_prefixes[2])
      port4_ip               = cidrhost(var.sdwan_subnet_prefixes[3], 5)
      port4_mask             = cidrnetmask(var.sdwan_subnet_prefixes[3])
      passive_peerip         = cidrhost(var.sdwan_subnet_prefixes[2], 6)
      defaultgwy             = cidrhost(var.sdwan_subnet_prefixes[0], 1)
      rfc1918gwy             = cidrhost(var.sdwan_subnet_prefixes[1], 1)
      ha_mgmt_gwy            = cidrhost(var.sdwan_subnet_prefixes[3], 1)
      mgmt_prefix            = cidrhost(var.sdwan_subnet_prefixes[3], 0)
      loopback               = var.fw_loopback
      transit_gateway_prefix = cidrhost(element(data.azurerm_virtual_network.remote_virtual_network.address_space, 0), 0)
      transit_gateway_length = cidrnetmask(element(data.azurerm_virtual_network.remote_virtual_network.address_space, 0))
      ars_vnet_cidr          = element(var.ars_address_space, 0)
      azure_region_summary   = var.azure_region_summary
      forti_as_num           = var.firewall_as_num
      forti_router_id        = cidrhost(var.sdwan_subnet_prefixes[1], 5)
      transit_gateway_as     = data.aviatrix_transit_gateway.transit_gateway.local_as_number
      transit_gateway        = data.aviatrix_transit_gateway.transit_gateway.bgp_lan_ip_list[1]
      transit_gateway_ha     = data.aviatrix_transit_gateway.transit_gateway.ha_bgp_lan_ip_list[1]
      ars-asn                = azurerm_route_server.ars.virtual_router_asn
      ars-0                  = tolist(azurerm_route_server.ars.virtual_router_ips)[0]
      ars-1                  = tolist(azurerm_route_server.ars.virtual_router_ips)[1]
    })
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = var.tags
}

