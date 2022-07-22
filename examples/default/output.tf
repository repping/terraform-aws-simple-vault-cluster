output "zz_bastion_easy_connect" {
  description = "Output that provides the full command to connect to the bastion instance"
  value       = <<-EOF
--------
Bastion SSH allowed from CIDR         : ${var.ssh_allowed_from}
AWS KMS key id used for auto unseal   : ${module.vault.aws_kms_key_id}

Connecting to the Bastion:
                     ssh-add ${module.bastion.ssh_privkey}
                     ssh -A ubuntu@${module.bastion.public_ip}

Connect to Vault nodes from Bastion:
          node 1 :   ssh ubuntu@${module.vault.vault-node-0}
          node 2 :   ssh ubuntu@${try(module.vault.vault-node-1, "unexisting-node")}
          node 3 :   ssh ubuntu@${try(module.vault.vault-node-2, "unexisting-node")}

Vault UI address:
          node 1 :   http://${module.vault.vault-node-0-gui}:${module.vault.vault_port}
          node 2 :   http://${module.vault.vault-node-1-gui}:${module.vault.vault_port}
          node 3 :   http://${module.vault.vault-node-2-gui}:${module.vault.vault_port}

Initialized Vault with:
vault operator init -recovery-shares=1 -recovery-threshold=1
--------
EOF
}