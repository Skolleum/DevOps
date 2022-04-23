output "ssh-cmd" {
  description = "SSH cmd to connect to the vm"
  value = "ssh -i ${local_sensitive_file.ssh_priv_key.filename} ${azurerm_linux_virtual_machine.node_vm.admin_username}@${azurerm_linux_virtual_machine.node_vm.public_ip_address}"
}