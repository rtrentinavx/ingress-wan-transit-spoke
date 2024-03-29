
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

resource "azurerm_network_interface" "firewall-2-port1" {
  name                          = "firewall-2-port1"
  location                      = data.azurerm_resource_group.resource-group.location
  resource_group_name           = data.azurerm_resource_group.resource-group.name
  enable_accelerated_networking = var.accelerate == "true" ? true : false
  enable_ip_forwarding          = true

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = module.vnet.vnet_subnets_name_id["publicsubnet"]
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost(var.subnet_prefixes[3], 6)
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
    private_ip_address            = cidrhost(var.subnet_prefixes[5], 6)
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

resource "azurerm_virtual_machine" "firewall-2" {
  name                             = var.firewall_name[1]
  location                         = var.location
  resource_group_name              = data.azurerm_resource_group.resource-group.name
  network_interface_ids            = [azurerm_network_interface.firewall-2-port1.id, azurerm_network_interface.firewall-2-port2.id]
  primary_network_interface_id     = azurerm_network_interface.firewall-2-port1.id
  vm_size                          = var.firewall_instance_size
  zones                            = [var.zone2]
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
    name              = "${var.firewall_name[1]}osDisk"
    caching           = "ReadWrite"
    managed_disk_type = "Standard_LRS"
    create_option     = "FromImage"
  }

  # Log data disks
  storage_data_disk {
    name              = "${var.firewall_name[1]}datadisk"
    managed_disk_type = "Standard_LRS"
    create_option     = "Empty"
    lun               = 0
    disk_size_gb      = "30"
  }

  os_profile {
    computer_name  = var.firewall_name[0]
    admin_username = data.azurerm_key_vault_secret.secret-firewall-username.value
    admin_password = data.azurerm_key_vault_secret.secret-firewall-password.value
    custom_data = templatefile("${path.module}/config-firewall-2.conf", {
      type          = var.firewall_image
      license_file  = var.license2
      firewall_name = var.firewall_name[1]
      port1_ip      = cidrhost(var.subnet_prefixes[3], 6)
      port1_mask    = cidrnetmask(var.subnet_prefixes[3])
      port2_ip      = cidrhost(var.subnet_prefixes[5], 6)
      port2_mask    = cidrnetmask(var.subnet_prefixes[5])
      defaultgwy    = cidrhost(var.subnet_prefixes[3], 1)
      rfc1918gwy    = cidrhost(var.subnet_prefixes[5], 1)
      adminsport    = var.adminsport
    })
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  boot_diagnostics {
    enabled     = true
    storage_uri = azurerm_storage_account.fgtstorageaccount.primary_blob_endpoint
  }
  tags = var.tags
}
