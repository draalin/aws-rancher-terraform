# AWS Highly available Rancher
Highly available Rancher setup with Terraform on AWS.

## Requirements
- An AWS account
- Minimum of Terraform version 14 and have setup the `provider.tf` and `variables.tf` with your preferred configuration.

## Terraform Documentation
You can find additional information [here](TERRAFORM_DOCS.md) on the Terraform:
- Requirements
- Providers
- Inputs
- Outputs

## How to run
Initialize providers
```
terraform init
```

Deploy infrastructure
```
terraform apply --auto-approve
```

Show infrastructure
```
terraform show
```

Show outputs
```
terraform output
```

Destroy infrastructure
```
terraform destroy --auto-approve
```

## Access rancher GUI
- Open browser to the terraform `rancher_url` output.
- Login with the username `admin` and the terraform `rancher_password` output.