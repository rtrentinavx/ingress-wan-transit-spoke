output "ActiveMGMTPublicIP" {
  value = azurerm_public_ip.ActiveMGMTIP[0].ip_address
}

output "PassiveMGMTPublicIP" {
  value = azurerm_public_ip.PassiveMGMTIP[0].ip_address
}