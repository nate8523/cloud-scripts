variable "client_name" {
  description = "Name of the client (used for resource naming)."
  type        = string
}

variable "location" {
  description = "Azure region for deployment."
  type        = string
  default     = "UK South"
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

variable "backup_disk_size_gb" {
  description = "Size of the additional backup disk in GB."
  type        = number
  default     = 1024
}
