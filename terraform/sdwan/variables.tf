variable "resource_group" { type = string }
variable "location" { type = string }
variable "virtual_network_name" { type = string }
variable "address_space" { type = list(string) }
variable "subnet" {
  type = map(object({
    name             = string
    address_prefixes = list(string)
  }))
}
variable "tags" {
  type = map(string)
}

variable "subscription_id" { type = string }
variable "client_id" { type = string }
variable "client_secret" { type = string }
variable "tenant_id" { type = string }

//  For HA, choose instance size that support 4 nics at least
//  Check : https://docs.microsoft.com/en-us/azure/virtual-machines/linux/sizes
variable "size" {
  type    = string
  default = "Standard_F4"
}

// Availability zones only support in certain
// Check: https://docs.microsoft.com/en-us/azure/availability-zones/az-overview
variable "zone1" {
  type    = string
  default = "1"
}

variable "zone2" {
  type    = string
  default = "2"
}

// To use custom image 
// by default is false
variable "custom" {
  default = false
}

//  Custom image blob uri
variable "customuri" {
  type    = string
  default = "<custom image blob uri>"
}

variable "custom_image_name" {
  type    = string
  default = "<custom image name>"
}

variable "custom_image_resource_group_name" {
  type    = string
  default = "<custom image resource group>"
}

// License Type to create FortiGate-VM
// Provide the license type for FortiGate-VM Instances, either byol or payg.
variable "license_type" {
  default = "payg"
}

// enable accelerate network, either true or false, default is false
// Make the the instance choosed supports accelerated networking.
// Check: https://docs.microsoft.com/en-us/azure/virtual-network/accelerated-networking-overview#supported-vm-instances
variable "accelerate" {
  default = "true"
}

variable "publisher" {
  type    = string
  default = "fortinet"
}

variable "fgtoffer" {
  type    = string
  default = "fortinet_fortigate-vm_v5"
}

// BYOL sku: fortinet_fg-vm
// PAYG sku: fortinet_fg-vm_payg_20190624
variable "fgtsku" {
  type = map(any)
  default = {
    byol = "fortinet_fg-vm"
    payg = "fortinet_fg-vm_payg_2022"
  }
}

// FOS version
variable "fgtversion" {
  type    = string
  default = "7.0.12"
}

variable "adminusername" {
  type    = string
  default = "azureadmin"
}

variable "adminpassword" {
  type    = string
  default = "Fortinet123#"
}

// HTTPS Port
variable "adminsport" {
  type    = string
  default = "8443"
}

variable "activeport1" {
  type = string
}

variable "activeport1mask" {
  type = string
  }

variable "activeport2" {
  type = string
  }

variable "activeport2mask" {
  type = string
  }

variable "activeport3" {
  type = string
  }

variable "activeport3mask" {
  type = string
  }

variable "activeport4" {
  type = string
  }

variable "activeport4mask" {
  type = string
  }

variable "passiveport1" {
  type = string
  }

variable "passiveport1mask" {
  type = string
  }

variable "passiveport2" {
  type = string
  }

variable "passiveport2mask" {
  type = string
  }

variable "passiveport3" {
  type = string
  }

variable "passiveport3mask" {
  type = string
  }

variable "passiveport4" {
  type = string
  }

variable "passiveport4mask" {
  type = string
  }

variable "port1gateway" {
  type = string
  }

variable "port2gateway" {
  type = string
  }

variable "bootstrap-active" {
  // Change to your own path
  type    = string
  default = "config-active.conf"
}

variable "bootstrap-passive" {
  // Change to your own path
  type    = string
  default = "config-passive.conf"
}


// license file for the active fgt
variable "license" {
  // Change to your own byol license file, license.lic
  type    = string
  default = "license.txt"
}

// license file for the passive fgt
variable "license2" {
  // Change to your own byol license file, license2.lic
  type    = string
  default = "license2.txt"
}

