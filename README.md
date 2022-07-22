# terraform-aws-vault
Opinionated module to deploy an unhardened Vault development cluster in AWS.
The cluster in configured with auto unseal via AWS KMS, this allows for developing without constantly unsealing.

## Prerequirements
- provide AWS credentials (via AWS CLI or ENV variables)
- Check the output after running `terraform apply` for further instructions. (Unique per example!)

## HOWTO:
1. Git clone the project
2. Navigate to an example deployment, i.e. `examples/default`
3. Run `terraform apply`
4. Check the Terraform output to connect to the Bastion and Vault nodes.

## Auto unseal
This modules deploys a cluster with auto unseal enabled via AWS KMS.
It also offers the option to supply your own AWS KMS key OR automatically generate one for you.
If it configured as an input in the `module "simple-vault-cluser" {}` block then it will be used, else it will be generated automatically.
> NOTE: 
> The KMS key has to allready exist before running `terraform apply` to deploy the Vault cluster. 
> The user supplied KMS key CANNOT be created in the same run this module creates the Vault cluster infrastructure!

## Inputs & Outputs

## Roadmap - TODO
example/default:
- auto scaling group
  - raft auto pilot + uitzoeken
- Domain in place
- ELB + cert + domain

- Variables
  - [ ] check vars in example and optionally move them to the cluster module and output them, then reference with module.output-name.
- [ ] basics:
  - [x] basic working code
    - [ ] example "default" --> single node works, 3/5 nodes TODO
  - [x] Documentation exists.
  - [ ] Variables have validation where applicable.
  - [ ] The repository has tags or releases.
  - [ ] Examples are tested in CI.
  - [ ] Examples pass in CI.
  - [ ] Module is published to The Registry.
- [x] cloud auto-join
- [x] cloud auto-unseal
  - [x] auto unseal basic implementation
  - [x] with auto key creation
  - [x] feature bring your own key.arn.id
  - [ ] convert to module (or not needed?)
- [ ] more examples
  - [ ] dynamoDB + s3 --> compare to NEW default example, refactor after DEFAULT example work with cluster
- [ ] TLS
  - [ ] module that spits out .crt .key .ca (see Gists)
  - [ ] SSL for API on 8200
  - [ ] SSL for RAFT on 8201
- [ ] logical hostnames (in CLI prompt) --> bastion works, vault nodes TODO
- [x] Refactor IAM, instance profile -> roles -> policies -> permissions
  - [x] move instance profile to cluster module
  - [x] double check auto-unseal code (awskms resource + roles/policies + user_Data) code is split over module and example
- [ ] auto unseal transit DEV/inmem cluster (cheaper then AWS KMS also :>)
- [x] input for node count so it can configured in the module block (1, 3 or 5 nodes only)
- [ ] skip or auto fix host fingerprint checking