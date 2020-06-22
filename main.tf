provider "azurerm" {
  version = "2.2.0"
  features {}
}

provider "random" {
  version = "2.2"
}

module "location_westeurope" {
  source = "./location"
  
  web_server_location = "westeurope"
  web_server_rg = "${var.web_server_rg}-westeurope"
  prefix  = "${var.prefix}-westeurope"
  web_server_address_space = "10.10.0.0/22"
  web_server_name = var.web_server_name
  environment = var.environment
  web_server_count = var.web_server_count
  web_server_subnets = {
    web-server = "10.10.1.0/24"
    bastion-server = "10.10.2.0/24"
  }
  terraform_script_version = var.terraform_script_version
  admin_password = data.azurerm_key_vault_secret.admin_password.value
}

module "location_northeurope" {
  source = "./location"
  
  web_server_location = "northeurope"
  web_server_rg = "${var.web_server_rg}-northeurope"
  prefix  = "${var.prefix}-northeurope"
  web_server_address_space = "10.20.0.0/22"
  web_server_name = var.web_server_name
  environment = var.environment
  web_server_count = var.web_server_count
  web_server_subnets = {
    web-server = "10.20.1.0/24"
    bastion-server = "10.20.2.0/24"
  }
  terraform_script_version = var.terraform_script_version
  admin_password = data.azurerm_key_vault_secret.admin_password.value
}