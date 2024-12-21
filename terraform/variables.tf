variable location {
  description = "Azure Location, e.g. West Europe, West US"
  type = string
}

variable subscription {
  description = "Azure Subscription ID"
  type = string
}

variable "vm_admin_username" {  
  description = "VM admin username"  
  type        = string  
} 

variable "ssh_public_key_path" {  
  description = "The path to the SSH public key file"  
  type        = string  
} 

