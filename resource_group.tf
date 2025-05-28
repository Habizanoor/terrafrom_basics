#create_resource_group
resource "azurerm_resource_group" "rg1" {
  name     = "terraform-rg"
  location = "eastus"
}

#public_ip
resource "azurerm_public_ip" "pip1" {
  name = "testpip"
  location = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  allocation_method = "Static"
  sku = "Standard"
}
#create_virtualnet
resource "azurerm_virtual_network" "vnet1" {
  name                = "testvnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
}


#create_subnet
resource "azurerm_subnet" "subn1" {
  name                 = "subnet1"
  resource_group_name  = azurerm_resource_group.rg1.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = ["10.0.2.0/24"]
}

#network_interface
resource "azurerm_network_interface" "nic1" {
  name                = "testnic"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subn1.id
    private_ip_address_allocation = "Dynamic"
  }
}

#cerate nsg
resource "azurerm_network_security_group" "nsg1" {
  name = "testnsg"
  location = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
}
resource "azurerm_network_security_rule" "allow_ssh" {
  resource_group_name = azurerm_resource_group.rg1.name
  name = "Allow_ssh"
  priority = 1000
  direction = "Inbound"
  access = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "22"
  source_address_prefix      = "*"
  destination_address_prefix = "*"
  network_security_group_name = azurerm_network_security_group.nsg1.name
}
resource "azurerm_subnet_network_security_group_association" "nsg_association" {
  subnet_id                 = azurerm_subnet.subn1.id
  network_security_group_id = azurerm_network_security_group.nsg1.id
}


#create virtual machine
resource "azurerm_linux_virtual_machine" "vm1" {
  name                = "testvm1"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location
  size                = "Standard_B1s"
  admin_username      = "azureuser"
  admin_password = "P@ssword1234567"
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.nic1.id,
  ]

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