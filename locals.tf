# local "installation-method" {
#   value = var.installation-method == "rpm" ? "rpm-vault-installation..sh.tpl" : ""
# }
locals {
  instance_name = "vault-${var.name}-${random_string.default.result}"
  cluster_name = "${var.cluster_name}_${random_string.default.result}"

  aws_kms_key_id = try(var.aws_kms_key_id, aws_kms_key.default[0].id)
}
