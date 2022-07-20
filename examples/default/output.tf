output "ssh_allowed_from" {
  value = var.ssh_allowed_from
}
output "zz_bastion_easy_connect" {
  description = "Output that provides the full command to connect to the bastion instance"
  value       = <<-EOF

--------
# AWS KMS key id used for auto unseal:
${module.vault.aws_kms_key_id}

# How to connect:
ssh-add ${module.bastion.ssh_privkey}
ssh -A ubuntu@${module.bastion.public_ip}

# Optional, ssh to the Vault cluster nodes:
node 1: 
ssh ubuntu@${module.vault.vault-node-0}
node 2: 
ssh ubuntu@${try(module.vault.vault-node-1, "1 node cluster")}
node 3: 
ssh ubuntu@${try(module.vault.vault-node-2, "1 node cluster")}

# Vault UI address:
node 1: 
http://${module.vault.vault-node-0-gui}:${module.vault.vault_port}
node 2: 
http://${module.vault.vault-node-1-gui}:${module.vault.vault_port}
node 3: 
http://${module.vault.vault-node-2-gui}:${module.vault.vault_port}
--------

export VAULT_ADDR="http://127.0.0.1:8200"
vault operator init -recovery-shares=1 -recovery-threshold=1
vault status
sudo journalctl -fexu vault.service

EOF
}