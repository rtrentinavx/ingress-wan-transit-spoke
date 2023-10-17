resource "azurerm_virtual_machine" "fgtvm" {
  name                         = var.firewall_name
  location                     = azurerm_resource_group.resource_group.location
  resource_group_name          = azurerm_resource_group.resource_group.name
  network_interface_ids        = [azurerm_network_interface.fgtport1.id, azurerm_network_interface.fgtport2.id, azurerm_network_interface.fgtport3.id]
  primary_network_interface_id = azurerm_network_interface.fgtport1.id
  vm_size                      = var.firewall_size
  storage_image_reference {
    publisher = var.publisher
    offer     = var.fgtoffer
    sku       = var.license_type == "byol" ? var.fgtsku["byol"] : var.fgtsku["payg"]
    version   = var.firewall_image_version
  }

  plan {
    name      = var.license_type == "byol" ? var.fgtsku["byol"] : var.fgtsku["payg"]
    publisher = var.publisher
    product   = var.fgtoffer
  }

  storage_os_disk {
    name              = "osDisk"
    caching           = "ReadWrite"
    managed_disk_type = "Standard_LRS"
    create_option     = "FromImage"
  }

  # Log data disks
  storage_data_disk {
    name              = "fgtvmdatadisk"
    managed_disk_type = "Standard_LRS"
    create_option     = "Empty"
    lun               = 0
    disk_size_gb      = "30"
  }

  os_profile {
    computer_name  = var.firewall_name
    admin_username = data.azurerm_key_vault_secret.secret-firewall-username.value
    admin_password = data.azurerm_key_vault_secret.secret-firewall-password.value
    custom_data    = data.template_file.fgtvm.rendered
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

data "template_file" "fgtvm" {
  template = file(var.bootstrap-fgtvm)
  vars = {
    type         = var.license_type
    license_file = var.license
  }
}
