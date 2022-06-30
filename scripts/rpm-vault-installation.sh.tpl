#!/bin/bash

# Install the Hashicorp repository
sudo apt update && sudo apt install -y gpg
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg >/dev/null
gpg --no-default-keyring --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg --fingerprint
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

# Install Vault
sudo apt update && sudo apt install -y vault

# Create Vault config
cat << EOF > /etc/vault.d/vault.hcl
ui = true
# disable_mlock = true

storage "file" {
  path = "/opt/vault/data"
}

# HTTPS listener
listener "tcp" {
  address       = "0.0.0.0:${port}"
#   tls_cert_file = "/opt/vault/tls/tls.crt"
#   tls_key_file  = "/opt/vault/tls/tls.key"
  tls_disable   = 1
}

# Enterprise license_path
#license_path = "/etc/vault.d/vault.hclic"
EOF

# Start and enable the Vault service
systemctl enable --now vault.service

# Set Vault address in the cli environment
export VAULT_ADDR='http://127.0.0.1:${port}'

# Initialize Vault
vault operator init > /home/ubuntu/initialisation.txt

# Remove Welcome Message upon logging in via SSH
sudo touch /home/ubuntu/.hushlogin