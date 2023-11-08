

provider "azurerm" {
    subscription_id = "65a38a6b-52d0-4a59-8f55-d3b200eba7e1"
    client_id = "a439bcfb-b3b3-4b3e-92d1-a243c86b942f"
    client_secret = "lTe8Q~K.iU0DyxeX-6XwLVSSmQ40uRKLuoRDbb53"
    tenant_id = "77bd1362-7e1e-40b1-8c7a-bc1032926fd1"
    skip_provider_registration = true

    features {}

}



resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = "terraform_group"
}

# Create virtual network
resource "azurerm_virtual_network" "my_network" {
  name                = "myVnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create subnet
resource "azurerm_subnet" "my_subnet" {
  name                 = "mySubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.my_network.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "my_terraform_public_ip1" {
  name                = "myPublicIP1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

resource "azurerm_public_ip" "my_terraform_public_ip2" {
  name                = "myPublicIP2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "my_terraform_nsg" {
  name                = "myNetworkSecurityGroup"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create network interface
resource "azurerm_network_interface" "my_terraform_nic1" {
  name                = "myNIC1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "my_nic_configuration"
    subnet_id                     = azurerm_subnet.my_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.my_terraform_public_ip1.id
  }
}
resource "azurerm_network_interface" "my_terraform_nic2" {
  name                = "myNIC2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "my_nic_configuration"
    subnet_id                     = azurerm_subnet.my_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.my_terraform_public_ip2.id
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "my_nisga" {
  network_interface_id      = azurerm_network_interface.my_terraform_nic2.id
  network_security_group_id = azurerm_network_security_group.my_terraform_nsg.id
}



# Create the first virtual machine
resource "azurerm_linux_virtual_machine" "my_terraform_vm_1" {
  name                  = "myVM-1"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.my_terraform_nic1.id]
  size                  = "Standard_DS1_v2"

  disable_password_authentication = false
  admin_password = "Gegejj13"


  os_disk {
    name                 = "myOsDisk-1"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  computer_name  = "hostname-1"
  admin_username = var.username
}

# Create the second virtual machine
resource "azurerm_linux_virtual_machine" "my_terraform_vm_2" {
  name                  = "myVM-2"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.my_terraform_nic2.id]
  size                  = "Standard_DS1_v2"
  disable_password_authentication = false

  admin_password = "Gegejj13"

  

  os_disk {
    name                 = "myOsDisk-2"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  computer_name  = "hostname-2"
  admin_username = var.username
}
