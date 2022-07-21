#!/bin/bash

# Install the Hashicorp repository
sudo apt update && sudo apt install -y gpg
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg >/dev/null
gpg --no-default-keyring --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg --fingerprint
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

# Install Vault
sudo apt update && sudo apt install -y vault

# Allow Vault to run the melock syscall without sudo/root
sudo setcap cap_ipc_lock=+ep /usr/local/bin/vault

# Set variables for the user_data provisioning runtime.
my_hostname="$(curl http://169.254.169.254/latest/meta-data/hostname)"
my_ipaddress="$(curl http://169.254.169.254/latest/meta-data/local-ipv4)"
my_instance_id="$(curl http://169.254.169.254/latest/meta-data/instance-id)"
my_region="$(curl http://169.254.169.254/latest/dynamic/instance-identity/document | grep region | cut -d\" -f4)"


# Create Vault config
sudo mkdir /etc/vault.d
cat << EOF > /etc/vault.d/vault.hcl
ui = true
disable_mlock = true
api_addr = "http://$${my_ipaddress}:8200"
cluster_addr = "http://$${my_ipaddress}:8201"

# storage "file" {
#   path = "/opt/vault"
# }

storage "raft" {
  path    = "/opt/vault/data"
  node_id = "$${my_instance_id}"
  retry_join {
    auto_join               = "provider=aws tag_key=Name tag_value=${instance_name} addr_type=private_v4 region=${region}"
    auto_join_scheme        = "http"
    # leader_ca_cert_file     = "${vault_path}/tls/vault_ca.crt"
    # leader_client_cert_file = "${vault_path}/tls/vault.crt"
    # leader_client_key_file  = "${vault_path}/tls/vault.pem"
  }
}

seal "awskms" {
  region     = "${kms_region}"
  kms_key_id = "${kms_key_id}"
}

# HTTPS listener
listener "tcp" {
  address             = "0.0.0.0:${port}"
  cluster_address     = "0.0.0.0:8201"
#   tls_cert_file       = "/opt/vault/tls/tls.crt"
#   tls_key_file        = "/opt/vault/tls/tls.key"
  tls_disable         = 1
}

# Enterprise license_path
#license_path = "/etc/vault.d/vault.hclic"
EOF


# Set Vault address in the cli environment
export VAULT_ADDR='http://127.0.0.1:${port}'

# Initialize Vault. Exists because else somebody could theoritically init vault via the Web UI, since it's enabled by default.
# vault operator init > /home/ubuntu/initialisation.txt

# Enable and start the vault.service
systemctl enable vault
# systemctl start vault

# export the vault_addr
echo "export VAULT_ADDR=\"http://127.0.0.1:8200\"" >> /root/.profile
echo "export VAULT_ADDR=\"http://127.0.0.1:8200\"" >> /home/ubuntu/.profile

# install vault cli auto-completion
vault -autocomplete-install

# Remove Welcome Message upon logging in via SSH
sudo touch /home/ubuntu/.hushlogin