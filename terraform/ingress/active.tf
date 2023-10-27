resource "azurerm_virtual_machine" "activefgtvm" {
  name                             = var.firewall_name[0]
  location                         = data.azurerm_resource_group.resource-group.location
  resource_group_name              = data.azurerm_resource_group.resource-group.name
  network_interface_ids            = [azurerm_network_interface.activeport1.id, azurerm_network_interface.activeport2.id]
  primary_network_interface_id     = azurerm_network_interface.activeport1.id
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
    custom_data = templatefile("${path.module}/config-active.conf", {
      type          = var.firewall_image
      license_file  = var.license
      firewall_name = var.firewall_name[0]
      port1_ip      = cidrhost(var.subnet_prefixes[3], 4)
      port1_mask    = cidrnetmask(var.subnet_prefixes[3])
      port2_ip      = cidrhost(var.subnet_prefixes[4], 4)
      port2_mask    = cidrnetmask(var.subnet_prefixes[4])
      defaultgwy    = cidrhost(var.subnet_prefixes[3], 1)
      rfc1918gwy    = cidrhost(var.subnet_prefixes[4], 1)
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

