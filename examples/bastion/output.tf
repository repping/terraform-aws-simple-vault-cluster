output "ssh_allowed_from" {
  value = var.ssh_allowed_from
}
output "zz_bastion_easy_connect" {
  description = "Output that provides the full command to connect to the bastion instance"
  value       = <<-EOF

--------
# Debugging AWS user_Data - user_Data script =
>>>>>>>>>>>>>>>>>>>>>>>
${module.simple-vault-cluster.vault_node_user_data}
<<<<<<<<<<<<<<<<<<<<<<<

# How to connect:
ssh-add ${module.simple-bastion.ssh_privkey}
ssh -A ubuntu@${module.simple-bastion.public_ip}

# Optional, ssh to the Vault cluster nodes:
node 1: ssh ubuntu@${module.simple-vault-cluster.vault-node-0}
node 2: ssh ubuntu@${try(module.simple-vault-cluster.vault-node-1, "1 node cluster")}
node 3: ssh ubuntu@${try(module.simple-vault-cluster.vault-node-2, "1 node cluster")}

export VAULT_ADDR="http://127.0.0.1:8200"
vault status

# Vault UI address:
node 1: http://${module.simple-vault-cluster.vault-node-0-gui}:${module.simple-vault-cluster.vault_port}
node 2: http://${module.simple-vault-cluster.vault-node-1-gui}:${module.simple-vault-cluster.vault_port}
node 3: http://${module.simple-vault-cluster.vault-node-2-gui}:${module.simple-vault-cluster.vault_port}
--------

EOF
}