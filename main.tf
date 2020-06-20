provider "azurerm" {
  version = "2.2.0"
  features {}
}

# Use alias if there are multiple subscription
# provider "azurerm" {
#   version = "2.2.0"
#   features {}
#   alias = "sub2"
# }

resource "azurerm_resource_group" "web_server_rg" {
  name     = var.web_server_rg
  location = var.web_server_location
}

resource "azurerm_virtual_network" "web_server_vnet" {
  name                = "${var.prefix}-vnet"
  location            = var.web_server_location
  resource_group_name = azurerm_resource_group.web_server_rg.name
  address_space       = [var.web_server_address_space]
}

resource "azurerm_subnet" "web_server_subnet" {
  for_each             = var.web_server_subnets
  name                 = each.key
  resource_group_name  = azurerm_resource_group.web_server_rg.name
  virtual_network_name = azurerm_virtual_network.web_server_vnet.name
  address_prefix       = each.value
}

resource "azurerm_network_interface" "web_server_nic" {
  name                = "${var.web_server_name}-${format("%02d", count.index)}-nic"
  location            = var.web_server_location
  resource_group_name = azurerm_resource_group.web_server_rg.name
  count               = var.web_server_count
  ip_configuration {
    name                          = "${var.web_server_name}-ip"
    subnet_id                     = azurerm_subnet.web_server_subnet["web-server"].id
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = count.index == 0 ? azurerm_public_ip.web_server_public_ip.id : null
  }
}

resource "azurerm_public_ip" "web_server_public_ip" {
  name                = "${var.web_server_name}-pip"
  location            = var.web_server_location
  resource_group_name = azurerm_resource_group.web_server_rg.name
  allocation_method   = var.environment == "production" ? "Static" : "Dynamic"
}

resource "azurerm_network_security_group" "web_server_nsg" {
  name                = "${var.web_server_name}-nsg"
  location            = var.web_server_location
  resource_group_name = azurerm_resource_group.web_server_rg.name


}

resource "azurerm_network_security_rule" "web_server_nsg_rule_rdp" {
  name                        = "RDP"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.web_server_rg.name
  network_security_group_name = azurerm_network_security_group.web_server_nsg.name
  count = var.environment == "production" ? 0 : 1
}

resource "azurerm_subnet_network_security_group_association" "web_server_sag" {
  network_security_group_id = azurerm_network_security_group.web_server_nsg.id
  subnet_id                 = azurerm_subnet.web_server_subnet["web-server"].id
}

resource "azurerm_windows_virtual_machine" "web-server" {
  name                = "${var.web_server_name}-${format("%02d", count.index)}"
  resource_group_name = azurerm_resource_group.web_server_rg.name
  location            = var.web_server_location
  availability_set_id = azurerm_availability_set.web_availability_set.id
  count               = var.web_server_count
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  admin_password      = "P@$$w0rd1234!"
  network_interface_ids = [
    azurerm_network_interface.web_server_nic[count.index].id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServerSemiAnnual"
    sku       = "Datacenter-Core-1709-smalldisk"
    version   = "latest"
  }
}

resource "azurerm_availability_set" "web_availability_set" {
  name                        = "${var.web_server_name}-availability-set"
  location                    = var.web_server_location
  resource_group_name         = azurerm_resource_group.web_server_rg.name
  managed                     = true
  platform_fault_domain_count = 2
}
