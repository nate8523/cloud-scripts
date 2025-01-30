output "vm_public_ip" {
  description = "Public IP address of the Veeam Backup VM"
  value       = azurerm_public_ip.public_ip.ip_address
}

output "vm_name" {
  description = "Virtual Machine Name"
  value       = azurerm_virtual_machine.vm.name
}

output "resource_group_name" {
  description = "Resource Group Name"
  value       = azurerm_resource_group.rg.name
}
