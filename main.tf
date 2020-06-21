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

locals {
  web_server_name = var.environment == "production" ? "${var.web_server_name}-prod" : "${var.web_server_name}-dev"
  build_environment = var.environment == "production" ? "production" : "development"
}
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
  name                = "${local.web_server_name}-${format("%02d", count.index)}-nic"
  location            = var.web_server_location
  resource_group_name = azurerm_resource_group.web_server_rg.name
  count               = var.web_server_count
  ip_configuration {
    name                          = "${local.web_server_name}-ip"
    subnet_id                     = azurerm_subnet.web_server_subnet["web-server"].id
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = count.index == 0 ? azurerm_public_ip.web_server_public_ip.id : null
  }
}

resource "azurerm_public_ip" "web_server_public_ip" {
  name                = "${local.web_server_name}-pip"
  location            = var.web_server_location
  resource_group_name = azurerm_resource_group.web_server_rg.name
  allocation_method   = var.environment == "production" ? "Static" : "Dynamic"
}

resource "azurerm_network_security_group" "web_server_nsg" {
  name                = "${local.web_server_name}-nsg"
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
  count                       = var.environment == "production" ? 0 : 1
}

resource "azurerm_subnet_network_security_group_association" "web_server_sag" {
  network_security_group_id = azurerm_network_security_group.web_server_nsg.id
  subnet_id                 = azurerm_subnet.web_server_subnet["web-server"].id
}

resource "azurerm_virtual_machine_scale_set" "web-server" {
  name                = "${var.prefix}-scale-set"
  resource_group_name = azurerm_resource_group.web_server_rg.name
  location            = var.web_server_location
  upgrade_policy_mode = "manual"

  sku {
    name     = "Standard_B1s"
    capacity = var.web_server_count
  }

  storage_profile_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServerSemiAnnual"
    sku       = "Datacenter-Core-1709-smalldisk"
    version   = "latest"
  }

  storage_profile_os_disk {
    name              = ""
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name_prefix = local.web_server_name
    admin_username       = "adminuser"
    admin_password       = "P@$$w0rd1234!"
  }

  os_profile_windows_config {
    provision_vm_agent = true
  }

  network_profile {
    name    = "web_server_network_profile"
    primary = true
    ip_configuration {
      name      = local.web_server_name
      primary   = true
      subnet_id = azurerm_subnet.web_server_subnet["web-server"].id
    }
  }
}
