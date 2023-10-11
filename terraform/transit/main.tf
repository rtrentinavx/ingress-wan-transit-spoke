
resource "azurerm_resource_group" "terraform-azure-resource-group" {
    name = var.resource_group
    location = var.location
    tags = {}
    }

resource "azurerm_virtual_network" "terraform-azure-virtual_network" {
  depends_on = [
    azurerm_resource_group.terraform-azure-resource-group
  ]
  name = var.virtual_network_name
  resource_group_name = azurerm_resource_group.terraform-azure-resource-group.name
  address_space = var.address_space
  location = azurerm_resource_group.terraform-azure-resource-group.location
  tags = {}
}

resource "azurem_subnet" "terraform-azure-subnet" {
  depends_on = [
    azurerm_virtual_network.terraform-azure-virtual_network
  ]
  for_each = var.subnet
  resource_group_name = azurerm_resource_group.terraform-azure-resource-group.name
  virtual_network_name = azurerm_virtual_network.terraform-azure-virtual_network.name
  name = each.value.name
  address_prefixes = each.value.address_prefixes
}

module "regions" {
  source       = "claranet/regions/azurerm"
  version      = "6.1.0"
  azure_region = azurerm_resource_group.terraform-azure-resource-group.location
}
resource "aviatrix_transit_gateway" "transit_gateway_azure" {
  depends_on = [
    azurem_subnet.terraform-azure-subnet
  ]
  account_name     = data.azurerm_subscription.current.display_name
  allocate_new_eip = var.allocate_new_eip
  bgp_ecmp                 = true
  bgp_lan_interfaces_count = "2"
  cloud_type               = "8"
  connected_transit        = true
  enable_transit_firenet   = true
  enable_bgp_over_lan = true
  #enable_egress_transit_firenet    = true 
  gw_name    = var.gw_name
  gw_size    = var.instance_size
  ha_subnet  = var.ha_gw_subnet
  ha_gw_size = var.instance_size
  insane_mode     = true
  local_as_number = var.local_as_number
  subnet          = var.gw_subnet
  vpc_id          = "${azurerm_virtual_network.terraform-azure-virtual_network.name}:${azurerm_resource_group.terraform-azure-resource-group.name}:${azurerm_virtual_network.terraform-azure-virtual_network.guid}"
  vpc_reg         = module.regions.location
  tags            = var.tags
}

resource "aviatrix_firenet" "firenet" {
  depends_on = [
    aviatrix_transit_gateway.transit_gateway_azure
  ]
  vpc_id          = "${azurerm_virtual_network.terraform-azure-virtual_network.name}:${azurerm_resource_group.terraform-azure-resource-group.name}:${azurerm_virtual_network.terraform-azure-virtual_network.guid}"
  inspection_enabled                  = true
  egress_enabled                      = true
  tgw_segmentation_for_egress_enabled = false
  hashing_algorithm                   = "5-Tuple"
}

resource "tls_private_key" "fw_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aviatrix_firewall_instance" "firewall_instance_1" {
  depends_on = [
    aviatrix_transit_gateway.transit_gateway_azure
  ]
  vpc_id          = aviatrix_transit_gateway.transit_gateway_azure.vpc_id
  firenet_gw_name = aviatrix_transit_gateway.transit_gateway_azure.gw_name
  firewall_name   = "${var.firewall_name}-001"
  firewall_image  = var.firewall_image
  firewall_size   = var.fw_instance_size
  egress_subnet   = element(azurerm_subnet.terraform-azure-subnet.address_prefixes["subnet01"], 0)
  ssh_public_key  = tls_private_key.fw_key.public_key_openssh
  username        = var.firewall_username
  tags            = var.fw_tags
  user_data       = ""
}

resource "aviatrix_firewall_instance" "firewall_instance_2" {
  depends_on = [
    aviatrix_transit_gateway.transit_gateway_azure
  ]
  vpc_id          = aviatrix_transit_gateway.transit_gateway_azure.vpc_id
  firenet_gw_name = aviatrix_transit_gateway.transit_gateway_azure.gw_name
  firewall_name   = "${var.firewall_name}-002"
  firewall_image  = var.firewall_image
  firewall_size   = var.fw_instance_size
  egress_subnet   = element(azurerm_subnet.terraform-azure-subnet.address_prefixes["subnet02"], 0)
  ssh_public_key  = tls_private_key.fw_key.public_key_openssh
  username        = var.firewall_username
  tags            = var.fw_tags
}

resource "aviatrix_firewall_instance_association" "firewall_instance_association_1" {
  depends_on = [
    aviatrix_firewall_instance.firewall_instance_1
  ]
  vpc_id               = aviatrix_firewall_instance.firewall_instance_1.vpc_id
  firenet_gw_name      = aviatrix_transit_gateway.transit_gateway_azure.gw_name
  instance_id          = aviatrix_firewall_instance.firewall_instance_1.instance_id
  firewall_name        = aviatrix_firewall_instance.firewall_instance_1.firewall_name
  lan_interface        = aviatrix_firewall_instance.firewall_instance_1.lan_interface
  management_interface = aviatrix_firewall_instance.firewall_instance_1.management_interface
  egress_interface     = aviatrix_firewall_instance.firewall_instance_1.egress_interface
  attached             = true
}

resource "aviatrix_firewall_instance_association" "firewall_instance_association_2" {
  depends_on = [
    aviatrix_firewall_instance.firewall_instance_2
  ]
  vpc_id               = aviatrix_firewall_instance.firewall_instance_2.vpc_id
  firenet_gw_name      = aviatrix_transit_gateway.transit_gateway_azure.gw_name
  instance_id          = aviatrix_firewall_instance.firewall_instance_2.instance_id
  firewall_name        = aviatrix_firewall_instance.firewall_instance_2.firewall_name
  lan_interface        = aviatrix_firewall_instance.firewall_instance_2.lan_interface
  management_interface = aviatrix_firewall_instance.firewall_instance_2.management_interface
  egress_interface     = aviatrix_firewall_instance.firewall_instance_2.egress_interface
  attached             = true
}