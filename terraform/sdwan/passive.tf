resource "azurerm_virtual_machine" "passivefgtvm" {
  depends_on                   = [azurerm_virtual_machine.activefgtvm]
  name                         = var.firewall_name[1]
  location                     = var.location
  resource_group_name          = data.azurerm_resource_group.resource-group.name
  network_interface_ids        = [azurerm_network_interface.passiveport1.id, azurerm_network_interface.passiveport2.id, azurerm_network_interface.passiveport3.id]
  primary_network_interface_id = azurerm_network_interface.passiveport1.id
  vm_size                      = var.fw_instance_size
  zones                        = [var.zone2]

  storage_image_reference {
    publisher =  var.publisher
    offer     =  var.fgtoffer
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
    name              = "${var.firewall_name[1]}passiveosDisk"
    caching           = "ReadWrite"
    managed_disk_type = "Standard_LRS"
    create_option     = "FromImage"
  }

  # Log data disks
  storage_data_disk {
    name              = "${var.firewall_name[1]}passivedatadisk"
    managed_disk_type = "Standard_LRS"
    create_option     = "Empty"
    lun               = 0
    disk_size_gb      = "30"
  }

  os_profile {
    computer_name  = var.firewall_name[0]
    admin_username = data.azurerm_key_vault_secret.secret-firewall-username.value
    admin_password = data.azurerm_key_vault_secret.secret-firewall-password.value
    custom_data    = templatefile("${path.module}/config-passive.conf", {
    type            = var.license_type
    license_file    = var.license2
    port1_ip        = var.passiveport1
    port1_mask      = var.passiveport1mask
    port2_ip        = var.passiveport2
    port2_mask      = var.passiveport2mask
    port3_ip        = var.passiveport3
    port3_mask      = var.passiveport3mask
    active_peerip   = var.activeport1
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
