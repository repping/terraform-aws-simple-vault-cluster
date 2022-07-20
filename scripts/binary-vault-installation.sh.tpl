#!/bin/bash
apt update && apt upgrade -y

# Create Vault user
sudo useradd --system --home /etc/vault.d --shell /bin/false vault
touch /home/ubuntu/.hushlogin

# Install Vault as binary
mkdir /usr/src/vault
cd /usr/src/vault
wget https://releases.hashicorp.com/vault/1.2.2/vault_1.2.2_linux_amd64.zip  # TODO wget vault.zip - make var so specific version can be defined
apt install -y unzip
unzip vault_1.2.2_linux_amd64.zip
apt remove -y unzip
mv vault /usr/local/bin
chmod 0755 /usr/local/bin/vault
chown vault:vault /usr/local/bin/vault

# Allow Vault to run the melock syscall without sudo/root
sudo setcap cap_ipc_lock=+ep /usr/local/bin/vault

# Set variables for the user_data provisioning runtime.
my_hostname="$(curl http://169.254.169.254/latest/meta-data/hostname)"
my_ipaddress="$(curl http://169.254.169.254/latest/meta-data/local-ipv4)"
my_instance_id="$(curl http://169.254.169.254/latest/meta-data/instance-id)"
my_region="$(curl http://169.254.169.254/latest/dynamic/instance-identity/document | grep region | cut -d\" -f4)"

mkdir -pm 0755 /etc/vault.d
mkdir -pm 0755 /opt/vault
chown vault:vault /opt/vault

# Create Vault config
sudo mkdir /etc/vault.d
cat << EOF > /etc/vault.d/vault.hcl
storage "file" {
  path = "/opt/vault"
}

# To be continued....# storage "raft" {
#   path    = "/opt/vault/data"
#   node_id = "$${my_instance_id}"
#   retry_join {
#     auto_join               = "provider=aws tag_key=Name tag_value=${instance_name} addr_type=private_v4 region=${region}"
#     auto_join_scheme        = "http"
#     # leader_ca_cert_file     = "${vault_path}/tls/vault_ca.crt"
#     # leader_client_cert_file = "${vault_path}/tls/vault.crt"
#     # leader_client_key_file  = "${vault_path}/tls/vault.pem"
#   }
# }

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

ui = true
disable_mlock = true
api_addr = "http://$${my_ipaddress}:8200"
cluster_addr = "http://$${my_ipaddress}:8201"

# Enterprise license_path
#license_path = "/etc/vault.d/vault.hclic"
EOF

# Create Vault Systemd service file
cat << EOF > /lib/systemd/system/vault.service
[Unit]
Description="HashiCorp Vault - A tool for managing secrets"
Documentation=https://www.vaultproject.io/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/vault.d/vault.hcl

[Service]
User=vault
Group=vault
ExecStart=/usr/local/bin/vault server -config=/etc/vault.d/vault.hcl
ExecReload=/bin/kill --signal HUP $MAINPID
KillMode=process
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo chmod 0644 /lib/systemd/system/vault.service
# cd /etc/systemd/system/multi-user.target.wants
# sudo ln -s /etc/systemd/system/vault.service vault.service # TODO check if neccesary, if yes then replace with systemd link or enable cmd.
systemctl daemon-reload


# Enable and start the vault.service
systemctl enable vault
systemctl start vault

# export the vault_addr
echo "export VAULT_ADDR=\"http://127.0.0.1:8200\"" >> /root/.profile
echo "export VAULT_ADDR=\"http://127.0.0.1:8200\"" >> /home/ubuntu/.profile

# install vault cli auto-completion
vault -autocomplete-install