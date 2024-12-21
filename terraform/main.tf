// Create random string  
resource random_string main {
  length           = 8
  upper            = false
  special          = false
}

// Input Data Block  
data "local_file" "public_key" {  
  filename = var.ssh_public_key_path  
} 

// Default Resource Group  
resource azurerm_resource_group default {
  name     = "rg-default"
  location = var.location
}

// Main Resource Group with random string suffix (VM will be created here) 
resource azurerm_resource_group main {
  name     = "rg-${random_string.main.result}"
  location = var.location
}


//
// Network (Default)
//

// Default Virtual Network  
resource azurerm_virtual_network default {
  name                = "vnet-default"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
  address_space       = ["10.0.0.0/16"]

}

// Default Subnet  
resource azurerm_subnet default {
  name                 = "snet-default"
  resource_group_name  = azurerm_resource_group.default.name
  virtual_network_name = azurerm_virtual_network.default.name
  address_prefixes     = ["10.0.1.0/24"]
}


//
// Network (Main)
//

// Main Network Security Group  
resource azurerm_network_security_group main {
  name                = "nsg-${random_string.main.result}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

// NSG rule to allow inbound SSH  
resource azurerm_network_security_rule rule1 {
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.main.name
  name                        = "allow-ssh"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  # source_address_prefix       = "${chomp(data.http.myip.body)}/32"
  destination_address_prefix  = "*"
}
# data "http" "myip" {
#   url = "http://ipv4.icanhazip.com"
# }

// NSG rule to allow inbound HTTP  
resource azurerm_network_security_rule rule2 {
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.main.name
  name                        = "allow-80"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

// Public IP for virtual machine  
resource azurerm_public_ip main {
  name                = "pip-vm${random_string.main.result}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"
}

// Network Interface for virtual machine  
resource azurerm_network_interface main {
  name                = "nic-vm${random_string.main.result}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "public"
    subnet_id                     = azurerm_subnet.default.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main.id
  }
}

// Association between NIC and NSG  
resource "azurerm_network_interface_security_group_association" "main" {  
  network_interface_id      = azurerm_network_interface.main.id  
  network_security_group_id = azurerm_network_security_group.main.id  
}  


//
// Virtual Machine
//

// Virtual Machine Block  
resource azurerm_linux_virtual_machine main {
  name                = "vm${random_string.main.result}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = "Standard_DS2_v2"
  admin_username      = var.vm_admin_username

  network_interface_ids = [
    azurerm_network_interface.main.id,
  ]

  admin_ssh_key {
    username   = var.vm_admin_username
    public_key = data.local_file.public_key.content  
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
      publisher = "Canonical"
      offer     = "0001-com-ubuntu-server-jammy"
      sku       = "22_04-lts"
      version   = "latest"
  }
}


//
// Ansible (prepare inventor.yaml)
//

locals {
  ansible_inventory = {
    all = {
      children = {
        webservers = {
          hosts = {
            "${azurerm_public_ip.main.ip_address}" = {
              ansible_user = var.vm_admin_username
            }
          }
        }
      }
    }
  }
}

# inventory.yml
# all:  
#   children:  
#     webservers:  
#       hosts:  
#         51.145.142.131:  
#           ansible_user: adminuser  

// Write Ansible inventory to a local file  
resource "local_file" "ansible_inventory" {
  content  = yamlencode(local.ansible_inventory)
  filename = "${path.module}/inventory.yml"
}

