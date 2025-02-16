Infra will match below project structure
```
terraform-aws-eks/
│
├── modules/
│   ├── eks/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── README.md
│   │
│   ├── vpc/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── README.md
│   │
│      
│
├── environments/
│   ├── dev/
│   │   ├── backend.tf
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── terraform.tfvars
│   │
│   ├── prod/
│       ├── backend.tf
│       ├── main.tf
│       ├── variables.tf
│       ├── terraform.tfvars
│
├── global/
│   ├── providers.tf
│   ├── variables.tf
│   ├── outputs.tf
│
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf
├── README.md
```
