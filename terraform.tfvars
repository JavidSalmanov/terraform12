web_server_location       = "westeurope"
web_server_rg             = "web-rg"
prefix                    = "web_server"
web_server_address_space  = "10.10.0.0/22"
web_server_address_prefix = "10.10.1.0/24"
web_server_name           = "web"
environment               = "development"
web_server_count          = 2
web_server_subnets = {
  web-server         = "10.10.1.0/24"
  bustion-server = "10.10.2.0/24"
}
terraform_script_version = "1.0.0"