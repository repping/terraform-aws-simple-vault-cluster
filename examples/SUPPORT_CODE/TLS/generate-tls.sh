#!/bin/zsh

# Create openssl.conf file in this folder
cat << EOF > ./openssl.conf
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no
[req_distinguished_name]
C = US
ST = State
L = SomeCity
O = MyCompany
OU = MyDivision
CN = www.company.com
[dn]
commonName = fake.vault.local
[v3_req]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names
[alt_names]
IP.1 = 127.0.0.1
DNS.1 = my_hostname
DNS.2 = localhost
EOF

# Generate the CA key
openssl genrsa -des3 -out vault-ca.key 4096 -config openssl.conf

# Generate the CA certificate
openssl req -x509 -new -nodes -key vault-ca.key -sha256 -days 10950 -out vault-ca.pem -config openssl.conf

# Remove the password from the key, so it can be used during AWS userdata provisioning.
openssl rsa -in vault-ca.key -out vault-ca.key

# Everything below should be run on the actual server that will host your application! 
# # Generate tls.key and tls.csr for *.example.local domain.
# # This command will create Subject Alternative Names (SANs) for 127.0.0.1, localhost, example.local, and *.example.local
# # Note the public ip in AWS has been added as a SAN.
# openssl req -new -nodes -newkey rsa:4096 -keyout vault.key -out vault.csr -batch -config openssl.conf

# # Generate and sign tls.crt for the domain *.example.local
# # AWS public ipv4 has been added again!
# # openssl x509 -req -in vault.csr -CA vault-ca.pem -CAkey vault-ca.key -CAcreateserial -out vault.crt -days 3650 -sha256
# openssl x509 -extfile openssl.cfg -extensions ext -req -in vault.csr -CA vault-ca.pem -CAkey vault-ca.key -CAcreateserial -out vault.crt -days 3650 -sha256


# # Bonus info == Add CA to OS trust store
# # # On CentOS
# # sudo cp ca.pem /etc/pki/ca-trust/source/anchors/ca.pem
# # sudo update-ca-trust

# # # On Ubuntu
# # sudo cp ca.pem /usr/local/share/ca-certificates/ca.pem
# # sudo update-ca-certificates