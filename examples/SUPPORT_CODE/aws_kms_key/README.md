# Introduction
This micro module exists as support for the other examples.

It creates an AWS KMS key for users to supply to the "simple-vault-cluster" module in the examples.
This simulates a user suppling their own key.

## Why not in the main.tf of the examples?
Terraform cannot handle creating the user-specified AWS KMS key in the same run that is uses the if/else statement to decide if an AWS KMS should be automatically created.
Alternatively `terraform apply -target="aws_kms_key.default"` can be used BUT this means the key will still be destroyed when the cluster is destroyed.
This way the key exists as long as the user is testing/developing.
Bonus: This also saves on cost! KMS keys cost $1 / month + is billed when created!