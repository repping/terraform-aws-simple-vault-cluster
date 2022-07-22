#!/bin/bash
# Userdata provisioning script for Vault cluster nodes in AWS EC2.
# Install the Hashicorp repository.
sudo apt update && sudo apt install -y gpg
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg >/dev/null
gpg --no-default-keyring --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg --fingerprint
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

# Install Vault.
sudo apt update && sudo apt install -y vault

# Allow Vault to run the melock syscall without sudo/root.
sudo setcap cap_ipc_lock=+ep /usr/bin/vault

# Set variables for the user_data provisioning runtime.
my_hostname="$(curl http://169.254.169.254/latest/meta-data/hostname)"
my_ipaddress="$(curl http://169.254.169.254/latest/meta-data/local-ipv4)"
my_instance_id="$(curl http://169.254.169.254/latest/meta-data/instance-id)"
my_region="$(curl http://169.254.169.254/latest/dynamic/instance-identity/document | grep region | cut -d\" -f4)"


# Create Vault config.
sudo mkdir -p /etc/vault.d
cat << EOF > /etc/vault.d/vault.hcl
ui = true
disable_mlock = true
api_addr = "https://$${my_ipaddress}:8200"
cluster_addr = "https://$${my_ipaddress}:8201"

storage "raft" {
  path    = "/opt/vault/data"
  node_id = "$${my_instance_id}"
  retry_join {
    auto_join               = "provider=aws tag_key=Name tag_value=${instance_name} addr_type=private_v4 region=${region}"
    auto_join_scheme        = "https"
    leader_ca_cert_file     = "${vault_path}/tls/vault-ca.pem"
    leader_client_cert_file = "${vault_path}/tls/vault.crt"
    leader_client_key_file  = "${vault_path}/tls/vault.key"
  }
}

seal "awskms" {
  region     = "${kms_region}"
  kms_key_id = "${kms_key_id}"
}

# HTTPS listener
listener "tcp" {
  address             = "$${my_ipaddress}:${port}"
  cluster_address     = "$${my_ipaddress}:8201"
  tls_cert_file       = "/opt/vault/tls/vault.crt"
  tls_key_file        = "/opt/vault/tls/vault.key"
  tls_client_ca_file  = "/opt/vault/tls/vault-ca.pem"
}
EOF

# Create Openssl config file for Vault.
cat << EOF > ${vault_path}/tls/openssl.cfg
[req]
distinguished_name = req_distinguished_name
req_extensions = ext
x509_extensions = ext
prompt = no
[req_distinguished_name]
C = US
ST = State
L = SomeCity
O = MyCompany
OU = MyDivision
CN = www.company.com
[dn]
commonName             = localhost
[ext]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names
[alt_names]
IP.1 = $${my_ipaddress}
IP.2 = 127.0.0.1
DNS.1 = $${my_hostname}
DNS.2 = localhost
EOF

# Place self-signed Vault Certificate Authority certificate.
echo "${vault_ca_cert}" > ${vault_path}/tls/vault-ca.pem
chown vault:vault ${vault_path}/tls/vault-ca.pem
chmod 600 ${vault_path}/tls/vault-ca.pem

# Place self-signed Vault Certificate Authority key.
echo "${vault_ca_key}" > ${vault_path}/tls/vault-ca.key
chown vault:vault ${vault_path}/tls/vault-ca.key
chmod 600 ${vault_path}/tls/vault-ca.key

# Generate Certificate Signing Request for the Vault Certificate Authority.
openssl req -config "${vault_path}/tls/openssl.cfg" -new -nodes -newkey rsa:4096 -keyout "${vault_path}/tls/vault.key" -extensions ext -out "${vault_path}/tls/vault.csr" -batch
chown vault:vault ${vault_path}/tls/vault.key
chmod 600 ${vault_path}/tls/vault.key

# Generate the Vault Certificate by signing the Certificate Signing Request with the Vault CA certificate + key.
openssl x509 -extfile "${vault_path}/tls/openssl.cfg" -extensions ext -req -in "${vault_path}/tls/vault.csr" -CA "${vault_path}/tls/vault-ca.pem" -CAkey "${vault_path}/tls/vault-ca.key" -CAcreateserial -out "${vault_path}/tls/vault.crt" -days 3650 -sha256
chown vault:vault ${vault_path}/tls/vault.crt
chmod 644 ${vault_path}/tls/vault.crt

# Cleanup.
rm -f ${vault_path}/tls/vault.csr
chown root:root ${vault_path}/tls/vault-ca.key
chmod 400 ${vault_path}/tls/vault-ca.key

# Enable and start the vault.service. Start currently disabled to make it easier to manually initialize the cluster after deployment.
systemctl enable vault
# systemctl start vault

# Export the Vault address.
echo "export VAULT_ADDR=\"https://$${my_ipaddress}:8200\"" >> /root/.profile

# Export vault CA as env var, fix for "Error checking seal status: Get "https://10.0.0.xxx:8200/v1/sys/seal-status": x509: certificate is not authorized to sign other certificates".
echo "export VAULT_CACERT=\"${vault_path}/tls/vault-ca.pem\"" >> /root/.profile

# Install vault CLI auto-completion.
vault -autocomplete-install

# Remove Welcome Message upon logging in via SSH.
sudo touch /home/ubuntu/.hushlogin