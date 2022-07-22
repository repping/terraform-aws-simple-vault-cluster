# Generate a 5 character hash to include in names/tags and make them unique.
resource "random_string" "default" {
  length  = 5
  numeric = false
  special = false
  upper   = false
}

# Create Vault cluster nodes.
resource "aws_instance" "vault-node" {
  count = var.cluster_size

  ami                         = var.ami
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.vault_instance.id
  instance_type               = var.instance_type
  key_name                    = var.ssh_pubkey
  subnet_id                   = var.subnet
  user_data = templatefile("${path.module}/scripts/${var.installation_method}-vault-installation.sh.tpl", {
    port          = var.vault_port,
    instance_name = local.instance_name,
    region        = var.region,
    vault_path    = "/opt/vault",
    kms_region    = var.region,
    kms_key_id    = "${local.aws_kms_key_id}"
    vault_ca_cert = file(var.vault_ca_cert)
    vault_ca_key  = file(var.vault_ca_key)
  })
  vpc_security_group_ids = [aws_security_group.vault-cluster.id]

  tags = merge(var.tags, { Name = local.instance_name })
}

# Create the security group for the vault nodes.
resource "aws_security_group" "vault-cluster" {
  description = "Security group to allow public inbound traffic to Vault on 8200"
  name        = "Vault"
  vpc_id      = var.vpc

  tags = var.tags
}

# Add port 8200/tcp inbound to the security group.
resource "aws_security_group_rule" "ingress_api" {
  type              = "ingress"
  description       = "allow inbound 8200"
  from_port         = var.vault_port
  to_port           = var.vault_port
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.vault-cluster.id
}

# Add port 8200/tcp inbound to the security group.
resource "aws_security_group_rule" "ingress_raft" {
  type              = "ingress"
  description       = "allow inbound 8200"
  from_port         = 8201
  to_port           = 8201
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.vault-cluster.id
}

# Add port 22/tcp inbound to the security group.
resource "aws_security_group_rule" "ingress_ssh" {
  type              = "ingress"
  description       = "allow inbound ssh from subnet"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.ssh_allowed_from]
  security_group_id = aws_security_group.vault-cluster.id
}

# Add rule to allow ALL outbound traffic to the security group.
resource "aws_security_group_rule" "egress_all" {
  type              = "egress"
  description       = "allow outbound all"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.vault-cluster.id
}

# Create a KMS key for auto unsealing WHEN NOT supplied by the user.
resource "aws_kms_key" "default" {
  count       = var.aws_kms_key_id == "" ? 1 : 0
  description = "Vault unseal key - ${local.cluster_name}"
  # tags        = local.tags
}

# Set an alias for the AWS KMS key
resource "aws_kms_alias" "default" {
  count         = var.aws_kms_key_id == "" ? 1 : 0
  name          = "alias/${local.cluster_name}-auto_generated"
  target_key_id = aws_kms_key.default[0].key_id
}

# Lookup the KMS key for auto unsealing WHEN supplied by the user.
data "aws_kms_key" "default" {
  count  = var.aws_kms_key_id == "" ? 0 : 1
  key_id = var.aws_kms_key_id
}