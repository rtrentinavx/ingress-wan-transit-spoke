resource "azurerm_virtual_machine" "passivefgtvm" {
  depends_on                   = [azurerm_virtual_machine.activefgtvm]
  name                         = var.firewall_name[1]
  location                     = var.location
  resource_group_name          = data.azurerm_resource_group.resource-group.name
  network_interface_ids        = [azurerm_network_interface.passiveport1.id, azurerm_network_interface.passiveport2.id, azurerm_network_interface.passiveport3.id]
  primary_network_interface_id = azurerm_network_interface.passiveport1.id
  vm_size                      = var.firewall_instance_size
  zones                        = [var.zone2]

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
    custom_data = templatefile("${path.module}/config-passive.conf", {
      type               = var.firewall_image
      license_file       = var.license2
      port1_ip        = cidrhost(var.subnet_prefixes[0],5)
      port1_mask      = cidrnetmask(var.subnet_prefixes[0])
      port2_ip        = cidrhost(var.subnet_prefixes[1],5)
      port2_mask      = cidrnetmask(var.subnet_prefixes[1])
      port3_ip        = cidrhost(var.subnet_prefixes[2],5)
      port3_mask      = cidrnetmask(var.subnet_prefixes[2])
      active_peerip  = cidrhost(var.subnet_prefixes[0],4)
      mgmt_gateway_ip = cidrhost(var.subnet_prefixes[0],1)
      defaultgwy      = cidrhost(var.subnet_prefixes[1],1)
      rfc1918gwy      = cidrhost(var.subnet_prefixes[2],1)
      transit_gateway_prefix = cidrhost(element(data.azurerm_virtual_network.remote_virtual_network.address_space,0),0)
      transit_gateway_lenght = cidrnetmask(element(data.azurerm_virtual_network.remote_virtual_network.address_space,0))
      tenant             = var.tenant_id
      subscription       = var.subscription_id
      clientid           = var.client_id
      clientsecret       = data.azurerm_key_vault_secret.secret-forti_client_secret.value
      adminsport         = var.adminsport
      rsg                = data.azurerm_resource_group.resource-group.name
      clusterip          = azurerm_public_ip.ClusterPublicIP.name
      routename          = azurerm_route_table.internal.name
      forti_as_num       = var.firewall_as_num
      forti_router_id    = var.firewall_passive_router_id
      transit_gateway_as = data.aviatrix_transit_gateway.transit_gateway.local_as_number
      transit_gateway    = data.aviatrix_transit_gateway.transit_gateway.bgp_lan_ip_list[1]
      transit_gateway_ha = data.aviatrix_transit_gateway.transit_gateway.ha_bgp_lan_ip_list[1]
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
