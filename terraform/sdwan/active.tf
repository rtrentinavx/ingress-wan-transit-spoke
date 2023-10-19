resource "azurerm_virtual_machine" "activefgtvm" {
  name                         = var.firewall_name[0]
  location                     = data.azurerm_resource_group.resource-group.location
  resource_group_name          = data.azurerm_resource_group.resource-group.name
  network_interface_ids        = [azurerm_network_interface.activeport1.id, azurerm_network_interface.activeport2.id, azurerm_network_interface.activeport3.id]
  primary_network_interface_id = azurerm_network_interface.activeport1.id
  vm_size                      = var.fw_instance_size
  zones                        = [var.zone1]

  storage_image_reference {
    publisher = var.publisher
    offer     = var.fgtoffer
    sku       = var.license_type == "byol" ? var.fgtsku["byol"] : var.fgtsku["payg"]
    version   = var.firewall_image_version
    id        = null
  }

  plan {
    name      = var.license_type == "byol" ? var.fgtsku["byol"] : var.fgtsku["payg"]
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
    custom_data    = templatefile("${path.module}/config-active.conf", {
    type         = var.license_type
    license_file = var.license
    port1_ip     = var.activeport1
    port1_mask   = var.activeport1mask
    port2_ip     = var.activeport2
    port2_mask   = var.activeport2mask
    port3_ip     = var.activeport3
    port3_mask   = var.activeport3mask
    passive_peerip  = var.passiveport1
    mgmt_gateway_ip = var.port1gateway
    defaultgwy      = var.port2gateway
    tenant          = var.tenant_id
    subscription    = var.subscription_id
    clientid        = var.client_id
    clientsecret    = var.client_secret
    adminsport      = var.adminsport
    rsg             = data.azurerm_resource_group.resource-group.name
    clusterip       = azurerm_public_ip.ClusterPublicIP.name
    routename       = azurerm_route_table.internal.name
  } )
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

