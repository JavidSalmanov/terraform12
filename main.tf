provider "azurerm" {
  version = "2.2.0"
  features {}
}

provider "random" {
  version = "2.2"
}

module "location_westeurope" {
  source = "./location"

  web_server_location      = "westeurope"
  web_server_rg            = "${var.web_server_rg}-westeurope"
  prefix                   = "${var.prefix}-westeurope"
  web_server_address_space = "10.10.0.0/22"
  web_server_name          = var.web_server_name
  environment              = var.environment
  web_server_count         = var.web_server_count
  web_server_subnets = {
    web-server     = "10.10.1.0/24"
    bastion-server = "10.10.2.0/24"
  }
  terraform_script_version = var.terraform_script_version
  admin_password           = data.azurerm_key_vault_secret.admin_password.value
  domain_name_label        = var.domain_name_label
}

module "location_northeurope" {
  source = "./location"

  web_server_location      = "northeurope"
  web_server_rg            = "${var.web_server_rg}-northeurope"
  prefix                   = "${var.prefix}-northeurope"
  web_server_address_space = "10.20.0.0/22"
  web_server_name          = var.web_server_name
  environment              = var.environment
  web_server_count         = var.web_server_count
  web_server_subnets = {
    web-server     = "10.20.1.0/24"
    bastion-server = "10.20.2.0/24"
  }
  terraform_script_version = var.terraform_script_version
  admin_password           = data.azurerm_key_vault_secret.admin_password.value
  domain_name_label        = var.domain_name_label
}

resource "azurerm_resource_group" "global_rg" {
  name     = "traffic-manager-rg"
  location = "westeurope"

}
resource "azurerm_traffic_manager_profile" "traffic_manager_profile" {
  name                   = "${var.prefix}-traffic-manager-profile"
  resource_group_name    = azurerm_resource_group.global_rg.name
  traffic_routing_method = "Weighted"

  dns_config {
    relative_name = var.domain_name_label
    ttl           = 100
  }

  monitor_config {
    protocol                     = "http"
    port                         = 80
    path                         = "/"
    interval_in_seconds          = 30
    timeout_in_seconds           = 9
    tolerated_number_of_failures = 3
  }
}

resource "azurerm_traffic_manager_endpoint" "traffic_manager_westeurope_profile" {
  name                = "${var.prefix}-traffic-manager-westeurope-profile"
  resource_group_name = azurerm_resource_group.global_rg.name
  profile_name        = azurerm_traffic_manager_profile.traffic_manager_profile.name
  target_resource_id  = module.location_westeurope.web_server_lb_public_ip_id
  type                = "azureEndpoints"
  weight              = 100
}

resource "azurerm_traffic_manager_endpoint" "traffic_manager_northeurope_profile" {
  name                = "${var.prefix}-traffic-manager-northeurope-profile"
  resource_group_name = azurerm_resource_group.global_rg.name
  profile_name        = azurerm_traffic_manager_profile.traffic_manager_profile.name
  target_resource_id  = module.location_northeurope.web_server_lb_public_ip_id
  type                = "azureEndpoints"
  weight              = 100
}
