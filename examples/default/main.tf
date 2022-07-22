data "aws_ami" "latest_ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

module "vpc" {
  source           = "../../../terraform-aws-vpc"
  cidr_block       = "10.0.0.0/16"
  public_subnet    = true
  region           = var.region
  ssh_allowed_from = var.ssh_allowed_from

  tags = {
    owner = "richarde"
    Name  = "vpc RE"
  }
}

module "bastion" {
  source = "../../../terraform-aws-bastion"

  ami              = data.aws_ami.latest_ubuntu.id
  instance_type    = "t2.micro"
  region           = var.region
  subnet           = module.vpc.vpc_public_subnet
  ssh_allowed_from = var.ssh_allowed_from
  ssh_pubkey       = file("test_ssh_key_rsa.pub")
  vpc              = module.vpc.vpc_id

  tags = {
    owner = "richarde"
    Name  = "bastion RE"
  }
}

module "vault" {
  source = "../../../terraform-aws-vault"

  ami                 = data.aws_ami.latest_ubuntu.id
  aws_kms_key_id      = var.aws_kms_key_id
  instance_type       = "t3.micro"
  cluster_size        = 3
  vault_port          = 8200
  region              = var.region
  installation_method = "rpm"
  subnet              = module.vpc.vpc_public_subnet
  ssh_allowed_from    = "10.0.0.0/16"
  ssh_pubkey          = module.bastion.ssh_pubkey
  vpc                 = module.vpc.vpc_id
  vault_ca_cert       = "../SUPPORT_CODE/TLS/vault-ca.pem"
  vault_ca_key        = "../SUPPORT_CODE/TLS/vault-ca.key"

  tags = {
    owner = "richarde"
  }
}