#
# ingress vnet 
#
resource "azurerm_resource_group" "resouce_group_ingress_vnet" {
  name     = var.resouce_group_ingress_vnet
  location = var.location
}

module "vnet" {
  source              = "Azure/vnet/azurerm"
  version             = "4.1.0"
  use_for_each        = true
  vnet_name           = var.vnet_name
  resource_group_name = azurerm_resource_group.resouce_group_ingress_vnet.name
  vnet_location       = azurerm_resource_group.resouce_group_ingress_vnet.location
  address_space       = var.address_space
  subnet_names        = var.subnet_names
  subnet_prefixes     = var.subnet_prefixes
}

# rtb 

# rt

# associations 

# deploy fortis

# deploy avx gateways 

# attach to the transit gws 


#
# sd-wan transport vnet 
#

# create vnet 

# peer vnet with transit 

# sg 

# rtb 

# rt

# subnet 

# associations 

# deploy fortis

#
# transit firenet
#


# create vnet 

# sg 

# rtb 

# rt

# subnet 

# associations 

# deploy fortis

# deploy avx transit gws

# bgpolan configuration (sw-wan)

# bgpolan configuration (ARS)