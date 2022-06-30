output "vault-node-0" {
  value = aws_instance.vault-node[0].private_ip
}
output "vault-node-1" {
  value = try(aws_instance.vault-node[1].private_ip, "NON-EXISTING-NODE")
}
output "vault-node-2" {
  value = try(aws_instance.vault-node[2].private_ip, "NON-EXISTING-NODE")
}
output "vault-node-0-gui" {
  value = aws_instance.vault-node[0].public_ip
}
output "vault-node-1-gui" {
  value = try(aws_instance.vault-node[1].public_ip, "NON-EXISTING-NODE")
}
output "vault-node-2-gui" {
  value = try(aws_instance.vault-node[2].public_ip, "NON-EXISTING-NODE")
}
output "vault_port" {
  value = var.vault_port
}
output "vault_node_user_data" {
  value = aws_instance.vault-node[0].user_data
}