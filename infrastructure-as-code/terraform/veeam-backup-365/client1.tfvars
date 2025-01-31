client_name         = "client1"
location            = "UK South"
subscription_id     = "00000000-0000-0000-0000-000000000000"
vm_size             = "Standard_B4ms"
admin_username      = "veeamadmin"
admin_password      = "P@ssw0rd123!"
computer_name       = "Veeam01"
backup_disk_size_gb = 1024
tags = {
  Environment = "Production"
  Client      = "client1"
  Project     = "VeeamBackup"
  ManagedBy   = "Terraform"
}
image_publisher = "veeam"
image_offer     = "office365backup"
image_sku       = "veeamoffice365backupv7"


