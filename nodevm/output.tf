output "ssh-cmd" {
  description = "SSH cmd to connect to the vm"
  value = "ssh ${azurerm_linux_virtual_machine.node_vm.admin_username}@${azurerm_linux_virtual_machine.node_vm.public_ip_address}"
}