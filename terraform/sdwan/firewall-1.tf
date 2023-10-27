resource "azurerm_virtual_machine" "firewall-1" {
  name                             = var.firewall_name[0]
  location                         = data.azurerm_resource_group.resource-group.location
  resource_group_name              = data.azurerm_resource_group.resource-group.name
  network_interface_ids            = [azurerm_network_interface.firewall-1-port1.id, azurerm_network_interface.firewall-1-port2.id, azurerm_network_interface.firewall-1-port3.id]
  primary_network_interface_id     = azurerm_network_interface.firewall-1-port1.id
  vm_size                          = var.firewall_instance_size
  zones                            = [var.zone1]
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
      port1_ip               = cidrhost(var.subnet_prefixes[0], 4)
      port1_mask             = cidrnetmask(var.subnet_prefixes[0])
      port2_ip               = cidrhost(var.subnet_prefixes[1], 4)
      port2_mask             = cidrnetmask(var.subnet_prefixes[1])
      port3_ip               = cidrhost(var.subnet_prefixes[2], 4)
      port3_mask             = cidrnetmask(var.subnet_prefixes[2])
      passive_peerip = cidrhost(var.subnet_prefixes[2], 5)
      defaultgwy             = cidrhost(var.subnet_prefixes[0], 1)
      rfc1918gwy             = cidrhost(var.subnet_prefixes[1], 1)
      hagwy = cidrhost(var.subnet_prefixes[2], 1)
      transit_gateway_prefix = cidrhost(element(data.azurerm_virtual_network.remote_virtual_network.address_space, 0), 0)
      transit_gateway_lenght = cidrnetmask(element(data.azurerm_virtual_network.remote_virtual_network.address_space, 0))
      adminsport             = var.adminsport
      forti_as_num           = var.firewall_as_num
      forti_router_id        = var.firewall_active_router_id
      transit_gateway_as     = data.aviatrix_transit_gateway.transit_gateway.local_as_number
      transit_gateway        = data.aviatrix_transit_gateway.transit_gateway.bgp_lan_ip_list[1]
      transit_gateway_ha     = data.aviatrix_transit_gateway.transit_gateway.ha_bgp_lan_ip_list[1]
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

