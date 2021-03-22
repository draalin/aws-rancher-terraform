## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.14 |
| aws | ~> 3.2 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 3.2 |
| helm | n/a |
| local | n/a |
| null | n/a |
| rancher2 | n/a |
| rancher2.bootstrap | n/a |
| random | n/a |
| rke | n/a |
| template | n/a |
| tls | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| domain\_name | domain name | `string` | n/a | yes |
| email | email | `string` | n/a | yes |
| password | rancher password | `string` | n/a | yes |
| vpc\_id | vpc id | `string` | n/a | yes |
| instance\_type | instance type | `string` | `"t2.large"` | no |
| kubernetes\_version | kubernetes version | `string` | `"v1.16.13-rancher1-2"` | no |
| nodes | nodes | `string` | `"3"` | no |
| project\_name | project name | `string` | `"rancher"` | no |
| rancher\_version | rancher version | `string` | `"v2.4.8"` | no |

## Outputs

| Name | Description |
|------|-------------|
| rancher\_ips | n/a |
| rancher\_password | n/a |
| rancher\_token | n/a |
| rancher\_url | n/a |

