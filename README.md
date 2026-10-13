# aws-grant-user-access

This project aims to grant assume-role access to an IAM user for a given AWS Role ARN with a time limited IAM policy.

<!--lint disable-->

* [aws-grant-user-access](#aws-grant-user-access)
  * [CI/CD pipeline](#cicd-pipeline)
    * [Where can I find a CI/CD pipeline for this code base?](#where-can-i-find-a-cicd-pipeline-for-this-code-base)
    * [How is the CI/CD pipeline configured?](#how-is-the-cicd-pipeline-configured)
  * [Setting up locally](#setting-up-locally)
    * [Running the code: Terragrunt](#running-the-code-terragrunt)
      * [aws-vault tool](#aws-vault-tool)
    * [Terraform](#terraform)
    * [Terragrunt](#terragrunt)
  * [How do I plan/apply terraform to an environment?](#how-do-i-planapply-terraform-to-an-environment)

<!--lint enable-->

## CI/CD pipeline

### Where can I find a CI/CD pipeline for this code base?

CI/CD for this repo is hosted centrally in [platsec-ci-terraform](https://github.com/hmrc/platsec-ci-terraform)
(account `987972305662`), not self-hosted in this repo:

* PR checks: Python lint/test (`aws_grant_user_access_pr_builder`) and Terraform lint/plan
  against the `development`/`production` accounts (`aws_grant_user_access_pr_jobs`)
* Lambda build/deploy: `aws_grant_user_access` (builds the Docker image, pushes to the
  shared platsec-ci ECR repo, deploys via `lambda:UpdateFunctionCode`) in
  `live/pipelines.tf`
* Terraform infra apply (`labs`/`live`, i.e. `development`/`production`):
  `aws_grant_user_access_terraform_pipeline` in `live/pipelines.tf`, reusing the shared
  `platsec_terraform_pipeline` module

### How is the CI/CD pipeline configured?

* The Lambda build/deploy pipeline expects a `docker.tar` artifact produced by the root
  [buildspec.yml](./buildspec.yml) (`make container-release` + `docker save`)
* The Terraform apply/plan pipelines invoke `./scripts/run.sh <plan|apply> <development|production>`
  in this repo, which internally maps those CI-facing names to this repo's own `labs`/`live`
  Makefile targets and directories (kept as-is to avoid any risk to the existing Terraform
  state bucket naming, which is derived from the `labs`/`live` environment name)

### Why there are two pipelines

* `aws-grant-user-access` ships the Lambda code: it builds the image, pushes it to ECR and updates
  the function code. It owns the deployed image, so Terraform ignores changes to the function's `image_uri`.
* `aws-grant-user-access-terraform` applies the infrastructure and the Lambda configuration.
  It only sets the `latest` image when it first creates the function.
* On a brand-new environment the code pipeline's deploy step fails until Terraform has created the
  function. Run the Terraform pipeline first (or after the image has been pushed once), then re-run
  the failed deploy step. Later merges need no manual steps.


## Making Terraform code changes

See [Setting up locally](#setting-up-locally) section below for relevant tools needed locally.

It is recommended to run command below after updating Terraform/Terragrunt files in this repository run

```bash
make tf-checks
```

To fix any linting violations

```bash
make tf-fmt
```

## How do I bootstrap an environment for terraform deployment?

```bash
make bootstrap-${ENV}
```

## How do I plan/apply terraform to an environment?

Use `labs` or `live` as the environment. The Makefile selects the corresponding
planner/applier profile for local execution through aws-vault. Account-ID exports
are not required; the account configuration is defined in Terraform/Terragrunt.

The Slack notifications PrivateLink service is configured separately for each environment
through the `slack_notifications_endpoint_name` input in
[labs networking](./terraform/labs/networking/terragrunt.hcl) and
[live networking](./terraform/live/networking/terragrunt.hcl).
The service must exist and allow connections from the respective AWS account.

There is [CI/CD pipeline](#cicd-pipeline) in place to test and apply new changes. However, in the event there is a
need to run/test applying terraform resources locally use the command below

```bash
make ${CMD}-${ENV}

# where CMD is one of: validate, plan or apply
# e.g. make plan-labs
```

## Setting up locally

Pre-requisites:

* [aws-vault tool](https://github.com/ByteNess/aws-vault#installing)
* Terraform
* Terragrunt

### Running the code: Terragrunt

Before installing or running anything please read this section as it contains important information regarding how we
execute Terraform.

We use [Terragrunt](#Terragrunt) as our interface to Terraform. Terragrunt is a thin wrapper around Terraform and
provides several key improvements over using Terraform directly. For example Terragrunt gives us the ability to keep
code much DRYer than otherwise possible. For more details check out the [Terragrunt website](https://terragrunt.gruntwork.io/).
By design we *do not* invoke Terraform directly, instead we invoke Terragrunt.

#### aws-vault tool

Install [aws-vault tool](https://github.com/ByteNess/aws-vault#installing).

```bash
brew install --cask aws-vault
```

See https://github.com/ByteNess/aws-vault#installing for installation steps on Linux and Windows

#### Terraform

**Install Terraform environment manager**

```bash
pip install tfenv
```

Or check https://github.com/tfutils/tfenv#manual

Install Terraform

```bash
tfenv install
```

This will install the version of Terraform set in the `.terraform-version` file.

#### Terragrunt

**Install Terragrunt environment manager**

1. Check out tgenv into any path (here is `${HOME}/.tgenv`)

```bash
git clone https://github.com/cunymatthieu/tgenv.git ~/.tgenv
```

2. Add `~/.tgenv/bin` to your `$PATH` any way you like

```bash
echo 'export PATH="$HOME/.tgenv/bin:$PATH"' >> ~/.bash_profile
```

OR you can make symlinks for `tgenv/bin/*` scripts into a path that is already added to your `$PATH`
(e.g. `/usr/local/bin`) `OSX/Linux Only!`

```bash
ln -s ~/.tgenv/bin/* /usr/local/bin
```

**Install Terragrunt**

```bash
tgenv install
```

This will install the version of Terragrunt set in the `.terragrunt-version` file.

## License

This code is open source software licensed under the [Apache 2.0 License](http://www.apache.org/licenses/LICENSE-2.0.html).
