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

resource "azurerm_resource_group" "web_server_rg"{
  name = "web_rg"
  location = "westeurope"
}