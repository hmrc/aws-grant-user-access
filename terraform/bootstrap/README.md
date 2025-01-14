# Bootstrap

This folder contains the terragrunt config required for storage and management of terraform state including s3 bucket
and dynamo table.  In order to allow changes, the state of the bootstrap is managed with the following steps

## For first time run

* Comment out the `generate "backend" {}` block in the terragrunt.hcl file and add the `generate "local" {}` config
  below

```hcl
generate "local" {
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  backend "local" {
    path = "${path_relative_to_include()}/bootstrap.tfstate"
  }
}
EOF
}
```

* Bootstrap resources for terraform s3 backend config (s3 bucket, dynamo table, etc)

```bash
aws-vault exec <profile> -- terragrunt init
aws-vault exec <profile> -- terragrunt plan
aws-vault exec <profile> -- terragrunt apply
```

* (Optional) you may wish to verify the backend.tf and bootstrap.tfstate files

```bash
❯ find .terragrunt-cache -type f -name '*backend.tf'
.terragrunt-cache/sxq6LJeYYII0ZCIcjJfLMG2BqnQ/RAcfo4l3w_fY2MAqs-r_9wiLoEo/bootstrap/backend.tf

❯ find .terragrunt-cache -type f -name 'bootstrap.tfstate'
.terragrunt-cache/sxq6LJeYYII0ZCIcjJfLMG2BqnQ/RAcfo4l3w_fY2MAqs-r_9wiLoEo/bootstrap/bootstrap.tfstate
```

* Uncomment the `generate "backend" {}` block. Comment out the `generate "local" {}` block.
* To migrate terraform state from local backend to s3 backend, run

```bash
aws-vault exec <profile> -- terragrunt init -migrate-state
```

* done ✅

## For successive runs

* Run

```bash
aws-vault exec <profile> -- terragrunt apply
```

* done ✅
