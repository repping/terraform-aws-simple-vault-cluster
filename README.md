# terraform-aws-simple-vault-cluster
Opinionated module to deploy an unhardened Vault development cluster.

## Roadmap
- basics:
  - Documentation exists.
  - Variables have validation where applicable.
  - The repository has tags or releases.
  - Examples are tested in CI.
  - Examples pass in CI.
  - Module is published to The Registry.
- hostnames (on cli)
- input for node count

## bugs
╷
│ Error: Provider produced inconsistent final plan
│ 
│ When expanding the plan for module.simple-vault-cluster.aws_instance.vault-node[0] to include new values learned so far during apply, provider "registry.terraform.io/hashicorp/aws" produced an invalid new value for .user_data: was
│ cty.StringVal("bb7b7b9ef340c341e4f80b0a2171fc336f17a63b"), but now cty.StringVal("8b4f8384b43bae62bca7c1fadf846c4b1f68ec9c").
│ 
│ This is a bug in the provider, which should be reported in the provider's own issue tracker.
╵