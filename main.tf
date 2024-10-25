provider "azurerm" {
  features {}
  subscription_id = "3f8e44d3-d8c1-4de5-ae8d-c8bf79c026bc"
  client_id       = "ecd5c103-6698-4f13-8c43-13001b0305b3"
  client_secret   = var.client_secret
  tenant_id       = "8ed8060b-ab64-4d75-b16c-04b927e5903b"
}

variable "client_secret" {}

resource "azurerm_resource_group" "rg" {
  name     = "rg-nginx-lab"
  location = "East US"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-nginx-lab"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "subnet-nginx-lab"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Criação do Network Security Group (NSG)
resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-nginx-lab"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 1010
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

}

resource "azurerm_public_ip" "public_ip" {
  name                    = "pip-nginx-lab"
  location                = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name
  allocation_method       = "Static"
  sku                     = "Standard"
  ddos_protection_mode    = "VirtualNetworkInherited"
  idle_timeout_in_minutes = 4
}

# Interface de rede
resource "azurerm_network_interface" "nic" {
  name                = "nic-nginx-lab"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

# Associação do NSG à NIC usando network_interface_security_group_association
resource "azurerm_network_interface_security_group_association" "nic_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# Definir a chave pública SSH no Linux VM
resource "azurerm_linux_virtual_machine" "vm" {
  name                = "vm-nginx-lab"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1s"

  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  computer_name  = "nginx-vm"
  admin_username = var.admin_username

  # Autenticação via chave SSH
  admin_ssh_key {
    username   = "infra"
    public_key = file("~/.ssh/id_rsa_azure.pub") # Carrega a chave pública diretamente
  }

  disable_password_authentication = true

custom_data = base64encode(<<EOF
#!/bin/bash
# Atualizar pacotes
apt-get update -y

# Instalar pacotes necessários para adicionar o repositório do Docker
apt-get install -y apt-transport-https ca-certificates curl software-properties-common

# Adicionar a chave GPG do Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# Adicionar o repositório do Docker
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# Instalar o Docker
apt-get update -y
apt-get install -y docker-ce

# Adicionar o usuário ao grupo do Docker
usermod -aG docker infra

# Iniciar e habilitar o Docker
systemctl start docker
systemctl enable docker
EOF
  )
}

output "public_ip_address" {
  value       = azurerm_public_ip.public_ip.ip_address
  description = "O endereço IP público da VM."
}

output "vm_name" {
  value       = azurerm_linux_virtual_machine.vm.name
  description = "O nome da máquina virtual."
}

output "nsg_security_rules" {
  value       = azurerm_network_security_group.nsg.security_rule[*].destination_port_range
  description = "Lista de portas liberadas nas regras de segurança do NSG"
}

output "admin_username" {
  value       = var.admin_username
  description = "O nome de usuário para acesso SSH."
}
