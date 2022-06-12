resource "azurerm_resource_group" "skolleum" {
  name     = "skolleum"
  location = "Germany West Central"
  tags = {
    "purpose" = "test"
  }
}

resource "azurerm_virtual_network" "node_vnet" {
  name                = "node_vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.skolleum.location
  resource_group_name = azurerm_resource_group.skolleum.name
}

resource "azurerm_subnet" "node_subnet1" {
  name                 = "node_subnet1"
  resource_group_name  = azurerm_resource_group.skolleum.name
  virtual_network_name = azurerm_virtual_network.node_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "node_public_ip" {
  name                = "node_public_ip"
  location            = azurerm_resource_group.skolleum.location
  resource_group_name = azurerm_resource_group.skolleum.name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_security_rule" "node_sec_rule" {
    network_security_group_name = azurerm_network_security_group.node_network_sec_group.name
    resource_group_name = azurerm_resource_group.skolleum.name
    access                     = "Allow"
    description                = "Allow ssh access"
    destination_address_prefix = "*"
    destination_port_range     = "22"
    direction                  = "Inbound"
    name                       = "SSH"
    priority                   = 1001
    protocol                   = "Tcp"
    source_address_prefix      = "*"
    source_port_range = "*"
}

resource "azurerm_network_security_group" "node_network_sec_group" {
  name                = "node_network_sec_group"
  location            = azurerm_resource_group.skolleum.location
  resource_group_name = azurerm_resource_group.skolleum.name
}

resource "azurerm_network_interface" "node_nic" {
  name                = "node_nic"
  location            = azurerm_resource_group.skolleum.location
  resource_group_name = azurerm_resource_group.skolleum.name
  ip_configuration {
    name                          = "node_nic_config"
    subnet_id                     = azurerm_subnet.node_subnet1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.node_public_ip.id
  }
}

resource "azurerm_network_interface_security_group_association" "node_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.node_nic.id
  network_security_group_id = azurerm_network_security_group.node_network_sec_group.id
}

resource "random_id" "node_storage_id" {
  keepers = {
    resource_group = azurerm_resource_group.skolleum.name
  }
  byte_length = 8
}

resource "azurerm_storage_account" "node_storage_account" {
  name                     = "diag${random_id.node_storage_id.hex}"
  location                 = azurerm_resource_group.skolleum.location
  resource_group_name      = azurerm_resource_group.skolleum.name
  account_kind             = "StorageV2"
  account_replication_type = "LRS"
  account_tier             = "Standard"
}

resource "local_sensitive_file" "ssh_priv_key" {
  content = tls_private_key.node-seckey.private_key_pem
  filename = "${azurerm_linux_virtual_machine.node_vm.name}.pem"
  file_permission = "600"
}

resource "tls_private_key" "node-seckey" {
  algorithm = "RSA"
  rsa_bits = 4096
}

resource "azurerm_linux_virtual_machine" "node_vm" {
  name                  = "node_vm"
  location              = azurerm_resource_group.skolleum.location
  resource_group_name   = azurerm_resource_group.skolleum.name
  network_interface_ids = [azurerm_network_interface.node_nic.id]
  size                  = "Standard_B2s"
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    name                 = "node_os_disk"
  }
  source_image_reference {
    publisher = "eurolinuxspzoo1620639373013"
    offer     = "centos-stream-8-0-free"
    sku       = "centos-stream-8-0-free"
    version   = "latest"
  }

  plan {
    name = "centos-stream-8-0-free"
    publisher = "eurolinuxspzoo1620639373013"
    product = "centos-stream-8-0-free"
  }

  computer_name                   = "nodevm"
  admin_username                  = "azuser"
  disable_password_authentication = true
  admin_ssh_key {
    username   = "azuser"
    public_key = tls_private_key.node-seckey.public_key_openssh
  }
  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.node_storage_account.primary_blob_endpoint
  }
  tags = {
    "applicationRole" = "main_vm"
  }
}

resource "azurerm_iothub" "iot_broker_iothub" {
  name                = "iot-broker-iothub"
  resource_group_name = azurerm_resource_group.skolleum.name
  location            = azurerm_resource_group.skolleum.location

  event_hub_retention_in_days = 1
  public_network_access_enabled = true
  event_hub_partition_count = 2
  sku {
    name     = "F1"
    capacity = 1
  }
}

