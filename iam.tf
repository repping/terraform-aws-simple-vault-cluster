resource "aws_iam_instance_profile" "vault_instance" {
  name_prefix = local.cluster_name
  path        = var.instance_profile_path
  role        = aws_iam_role.vault_instance.name

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role" "vault_instance" {
  name_prefix        = local.cluster_name
  assume_role_policy = data.aws_iam_policy_document.vault_instance.json

  permissions_boundary = var.iam_permissions_boundary

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_iam_policy_document" "vault_instance" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# IAM - auto unseal permissions
data "aws_iam_policy_document" "autounseal" {
  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt",
    ]
    resources = ["*"]
    # resources = [aws_kms_key.default.arn]
  }
}

# IAM - auto-unseal - link policy to the default role.
resource "aws_iam_role_policy" "autounseal" {
  name   = "${local.cluster_name}-autounseal"
  policy = data.aws_iam_policy_document.autounseal.json
  role   = aws_iam_role.vault_instance.id
}