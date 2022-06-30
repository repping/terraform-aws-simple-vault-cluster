#!/bin/bash
apt update && apt upgrade -y

# Create Vault user
useradd -u 998 -s /bin/false vault
touch /home/ubuntu/.hushlogin

# Install Vault as binary
mkdir /usr/src/vault
cd /usr/src/vault
wget https://releases.hashicorp.com/vault/1.2.2/vault_1.2.2_linux_amd64.zip
apt install -y unzip
unzip vault_1.2.2_linux_amd64.zip
apt remove -y unzip
mv vault /usr/local/bin

# Create Vault config
sudo mkdir /etc/vault.d
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

# Create Vault Systemd service file
cat << EOF > /lib/systemd/system/vault.service
# vault.service multi user wants link
lrwxrwxrwx 1 root root 33 Jun 29 17:08 /etc/systemd/system/multi-user.target.wants/vault.service -> /lib/systemd/system/vault.service

# cat /lib/systemd/system/vault.service
[Unit]
Description="HashiCorp Vault - A tool for managing secrets"
Documentation=https://www.vaultproject.io/docs/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/vault.d/vault.hcl
StartLimitIntervalSec=60
StartLimitBurst=3

[Service]
Type=notify
EnvironmentFile=/etc/vault.d/vault.env
User=vault
Group=vault
ProtectSystem=full
ProtectHome=read-only
PrivateTmp=yes
PrivateDevices=yes
SecureBits=keep-caps
AmbientCapabilities=CAP_IPC_LOCK
CapabilityBoundingSet=CAP_SYSLOG CAP_IPC_LOCK
NoNewPrivileges=yes
ExecStart=/usr/bin/vault server -config=/etc/vault.d/vault.hcl
ExecReload=/bin/kill --signal HUP $MAINPID
KillMode=process
KillSignal=SIGINT
Restart=on-failure
RestartSec=5
TimeoutStopSec=30
LimitNOFILE=65536
LimitMEMLOCK=infinity

[Install]
WantedBy=multi-user.target
EOF

sudo chmod 0644 /lib/systemd/system/vault.service
cd /etc/systemd/system/multi-user.target.wants
sudo ln -s /lib/systemd/system/vault.service vault.service
sudo systemctl daemon-reload