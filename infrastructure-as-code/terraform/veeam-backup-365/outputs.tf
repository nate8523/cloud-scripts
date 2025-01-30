output "vm_public_ip" {
  description = "Public IP address of the Veeam Backup VM."
  value       = azurerm_public_ip.public_ip.ip_address
}
