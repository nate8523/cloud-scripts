provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.client_name}-veeam-backup-rg"
  location = var.location
  tags = var.tags
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.client_name}-veeam-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags = var.tags
}

resource "azurerm_subnet" "subnet" {
  name                 = "${var.client_name}-veeam-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "public_ip" {
  name                = "${var.client_name}-veeam-public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
  sku = "Basic"
  tags = var.tags
}

resource "azurerm_network_interface" "nic" {
  name                = "${var.client_name}-veeam-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

resource "azurerm_storage_account" "diag_storage" {
  name                     = "${var.client_name}diagstg"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = var.tags
}


resource "azurerm_marketplace_agreement" "imageTerms" {
  publisher = var.image_publisher
  offer     = var.image_offer
  plan      = var.image_sku
}

resource "azurerm_virtual_machine" "vm" {
  name                  = "${var.client_name}-veeam-vm"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic.id]
  vm_size               = var.vm_size
  tags = var.tags

  storage_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = var.image_version
  }

  plan {
    name      = var.image_sku
    product   = var.image_offer
    publisher = var.image_publisher
  }

  depends_on = [azurerm_marketplace_agreement.imageTerms] # Ensures terms are accepted before deploying VM

  storage_os_disk {
    name              = "${var.client_name}-veeam-os-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  os_profile {
    computer_name  = "veeam-backup"
    admin_username = var.admin_username
    admin_password = var.admin_password
  }

  os_profile_windows_config {
    provision_vm_agent = true
  }

    boot_diagnostics {
    enabled     = true
    storage_uri = azurerm_storage_account.diag_storage.primary_blob_endpoint
  }

}

resource "azurerm_managed_disk" "backup_disk" {
  name                 = "${var.client_name}-veeam-backup-disk"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = var.backup_disk_size_gb
  tags = var.tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "backup_disk_attach" {
  managed_disk_id    = azurerm_managed_disk.backup_disk.id
  virtual_machine_id = azurerm_virtual_machine.vm.id
  lun                = "01"
  caching            = "ReadWrite"
}

resource "azurerm_virtual_machine_extension" "disk_mount_script" {
  name                 = "disk-mount-script"
  virtual_machine_id   = azurerm_virtual_machine.vm.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = <<SETTINGS
  {
    "commandToExecute": "powershell -ExecutionPolicy Unrestricted -Command Invoke-WebRequest -Uri '${var.github_raw_url}' -OutFile 'C:\\AzureData\\initialize-disk.ps1'; powershell -ExecutionPolicy Unrestricted -File C:\\AzureData\\initialize-disk.ps1"
  }
  SETTINGS

  depends_on = [azurerm_virtual_machine.vm]
}
