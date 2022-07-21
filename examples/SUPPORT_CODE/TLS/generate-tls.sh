#!/bin/zsh

# Generate the CA key
openssl genrsa -des3 -out ca.key 4096

# Generate the CA certificate
openssl req -x509 -new -nodes -key ca.key -sha256 -days 10950 -out ca.pem -subj "/C=US/ST=State/L=City/O=FullName (Private) Limited/OU=Development/CN=Dummy Development Certificate Authority"


# Generate tls.key and tls.csr for *.example.local domain.
# This command will create Subject Alternative Names (SANs) for 127.0.0.1, localhost, example.local, and *.example.local
# Note the public ip in AWS has been added as a SAN.
openssl req -new -nodes -newkey rsa:4096 -keyout tls.key -out tls.csr -batch -subj "/C=US/ST=State/L=City/O=FullName (Private) Limited/OU=Development/CN=example.local" -reqexts SAN -config <(cat /etc/pki/tls/openssl.cnf <(printf "[SAN]\nsubjectAltName=IP:127.0.0.1,DNS:localhost,DNS:example.local,DNS:*.example.local"))

# Generate and sign tls.crt for the domain *.example.local
# AWS public ipv4 has been added again!
openssl x509 -req -in tls.csr -CA ca.pem -CAkey ca.key -CAcreateserial -out tls.crt -days 3650 -sha256 -extfile <(printf "subjectAltName=IP:127.0.0.1,DNS:localhost,DNS:example.local,DNS:*.example.local")


# Bonus info == Add CA to OS trust store
# # On CentOS
# sudo cp ca.pem /etc/pki/ca-trust/source/anchors/ca.pem
# sudo update-ca-trust

# # On Ubuntu
# sudo cp ca.pem /usr/local/share/ca-certificates/ca.pem
# sudo update-ca-certificates