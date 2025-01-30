variable "client_name" {
  description = "Name of the client (used for resource naming)."
  type        = string
}

variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "location" {
  description = "Azure region for deployment."
  type        = string
  default     = "UK South"
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}

variable "image_publisher" {
  description = "Publisher of the image"
  type        = string
}

variable "image_offer" {
  description = "Offer name for the image"
  type        = string
}

variable "image_sku" {
  description = "SKU for the image"
  type        = string
}

variable "image_version" {
  description = "version for the image"
  type        = string
  default     = "latest"
}


variable "vm_size" {
  description = "Size of the VM."
  type        = string
  default     = "Standard_B4ms"
}

variable "admin_username" {
  description = "Admin username for the VM."
  type        = string
}

variable "admin_password" {
  description = "Admin password for the VM."
  type        = string
  sensitive   = true
}

variable "computer_name" {
  description = "Windows computer name"
  type        = string
}

variable "backup_disk_size_gb" {
  description = "Size of the additional backup disk in GB."
  type        = number
  default     = 1024
}

variable "github_raw_url" {
  description = "Raw GitHub URL of the PowerShell script"
  type        = string
  default     = "https://raw.githubusercontent.com/nate8523/cloud-scripts/refs/heads/main/infrastructure-as-code/terraform/veeam-backup-365/initialize-disk.ps1"
}

