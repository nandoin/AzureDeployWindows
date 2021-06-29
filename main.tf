# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.46.0"
    }
  }
}
# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}

  subscription_id = "${var.subscription}"
  tenant_id = "${var.tenant}"
}

resource "azurerm_resource_group" "luizf" {
    name = "${var.prefix}"
    location = "${var.location}"
}

resource "azurerm_virtual_network" "luizf" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.luizf.location
  resource_group_name = azurerm_resource_group.luizf.name
}

resource "azurerm_subnet" "internal" {
  name                 = "${var.prefix}-internal"
  resource_group_name  = azurerm_resource_group.luizf.name
  virtual_network_name = azurerm_virtual_network.luizf.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "public" {
    name                         = "${var.prefix}-public"
    location                     = "${var.location}"
    resource_group_name          = azurerm_resource_group.luizf.name
    allocation_method            = "Dynamic"
}


resource "azurerm_network_interface" "luizf" {
  name                = "${var.prefix}-nic"
  resource_group_name = azurerm_resource_group.luizf.name
  location            = azurerm_resource_group.luizf.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public.id
  }
}
# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "luizf" {
    network_interface_id      = azurerm_network_interface.luizf.id
    network_security_group_id = azurerm_network_security_group.luizf.id
}
resource "azurerm_network_security_group" "luizf" {
    name                = "${var.prefix}-securitygroup"
    location            = "${var.location}"
    resource_group_name = azurerm_resource_group.luizf.name

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
    security_rule {
        name                       = "WTS"
        priority                   = 1002
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "3389"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
    security_rule {
        name                       = "WINRT"
        priority                   = 1003
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "5986"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    security_rule {
        name                       = "WEB"
        priority                   = 1004
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "80"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
}
resource "azurerm_windows_virtual_machine" "luizf" {
  name                            = "fernando-ops"
  resource_group_name             = azurerm_resource_group.luizf.name
  location                        = azurerm_resource_group.luizf.location
  size                            = "Standard_F2"
  admin_username                  = "administrador"
  admin_password                  = "securepass"
  network_interface_ids = [
    azurerm_network_interface.luizf.id,
  ]

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
}





