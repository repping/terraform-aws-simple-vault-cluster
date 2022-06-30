resource "aws_instance" "vault-node" {
  count = 3

  ami                         = var.ami
  associate_public_ip_address = true
  instance_type               = var.instance_type
  key_name                    = var.ssh_pubkey
  subnet_id                   = var.subnet
  # user_data                   = file("${path.module}/scripts/rpm-vault-installation.sh")
  user_data                   = templatefile("${path.module}/scripts/binary-vault-installation.sh.tpl", { port = var.vault_port })
  vpc_security_group_ids      = [aws_security_group.vault-cluster.id]

  tags = var.tags
}

resource "aws_security_group" "vault-cluster" {
  description = "Security group to allow public inbound traffic to Vault on 8200"
  name        = "Vault"
  vpc_id      = var.vpc

  tags = var.tags
}

resource "aws_security_group_rule" "ingress_api" {
  type              = "ingress"
  description       = "allow inbound 8200"
  from_port         = var.vault_port
  to_port           = var.vault_port
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.vault-cluster.id
}


resource "aws_security_group_rule" "ingress_ssh" {
  type              = "ingress"
  description       = "allow inbound ssh from subnet"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.ssh_allowed_from]
  security_group_id = aws_security_group.vault-cluster.id
}


resource "aws_security_group_rule" "egress_all" {
  type              = "egress"
  description       = "allow outbound all"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.vault-cluster.id
}