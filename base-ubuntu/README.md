# Packer template
A packer template for building base AMIs.

## Preparation
Updating:
- Copy the `**ENV**-validator.pem` file to the `files/validator.pem`. It is .gitignored, so it will not be committed to the repository. If the chef server has been rebuilt you will need the newest validator.

First time setup (new env):
- copy the desired `**ENV_NAME**-vars.json` to `**NEW_ENV_NAME**-vars.json` and modify appropriately. Only calling out unique values:
  - `ruby_version`: the version of ruby that will be installed with rbenv
- copy the encrypted data bag secret into: `files/encrypted_data_bag_secret`



## Random Notes, assumptions, and gotchas
- assumption: you have your aws credentails set up correctly
- assumption: you will have an env coobook matching this pattern: `${COMPANY_NAME}-env-${ENV_NAME}`
- assumption: you will have a chef server that can be reached matching this pattern: `"https://${DOMAIN}/organizations/${ORG}"`
- assumption: you will have a validator for bootstrap purposes matching this pattern: `${ENV}-validator`
- gotcha: you need to move your validator into `base-ubuntu/files/validator.pem` which will be git ignored.
- assumption: you will specify ec2 user data such as this when actually launching: `env=${ENV}&role=${ROLE}&domain=${DOMAIN}&org=${ORG}&company=${COMPANY}`




## Subnet
You should build it in a public subnet so it can make its security group and have access to the world.

## Usage
Run:
  - Dev: `packer build -var-file=dev-vars.json base.json`
  - Build: `packer build -var-file=build-vars.json base.json`
  - QA: `packer build -var-file=qa-vars.json base.json`
  - Demo: `packer build -var-file=demo-vars.json base.json`
  - Prod-West: `packer build -var-file=prod-west-vars.json base.json`


**Variables**:

* `AMI_NAME` - What name to use for this AMI for viewing in the web console
* `AWS_ACCESS_KEY_ID` - Access key for packer IAM
* `AWS_SECRET_ACCESS_KEY` - Secret key for packer IAM
* `AWS_DEFAULT_REGION` - Region for new AMI
* `SUBNET_ID` - VPC subnet ID for packer-created instance
* `VPC_ID` - VPC ID for packer-created instance
