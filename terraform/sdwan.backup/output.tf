output "firewall-1-MGMTPublicIP" {
  value = azurerm_public_ip.firewall-1-MGMTIP[0].ip_address
}

output "firewall-2-MGMTPublicIP" {
  value = azurerm_public_ip.firewall-2-MGMTIP[0].ip_address
}