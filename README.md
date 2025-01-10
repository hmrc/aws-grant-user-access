# aws-grant-user-access

This project aims to grant assume-role access to an IAM user for a given AWS Role ARN with a time limited IAM policy. 

- [aws-grant-user-access](#aws-grant-user-access)
  - [CI/CD pipeline](#cicd-pipeline)
    - [Where can I find a CI/CD pipeline for this code base?](#where-can-i-find-a-cicd-pipeline-for-this-code-base)
    - [How is the CI/CD pipeline configured?](#how-is-the-cicd-pipeline-configured)
  - [Setting up locally](#setting-up-locally)
    - [Running the code: Terragrunt](#running-the-code-terragrunt)
      - [aws-vault tool](#aws-vault-tool)
    - [Terraform](#terraform)
    - [Terragrunt](#terragrunt)
  - [How do I plan/apply terraform to an environment?](#how-do-i-planapply-terraform-to-an-environment)

## CI/CD pipeline

### Where can I find a CI/CD pipeline for this code base?

- [PR build job](https://eu-west-2.console.aws.amazon.com/codesuite/codebuild/638924580364/projects/grant-user-access-pr-builder/history?region=eu-west-2)
- [Deployment pipeline](https://eu-west-2.console.aws.amazon.com/codesuite/codepipeline/pipelines/grant-user-access-pipeline/view?region=eu-west-2)
- [Container Release Builder](https://eu-west-2.console.aws.amazon.com/codesuite/codebuild/638924580364/projects/grant-user-access-container-release-builder/history?region=eu-west-2)
  - release changes to `aws_grant_user_access` python code

### How is the CI/CD pipeline configured?

- PR build job is an [AWS CodeBuild project](https://eu-west-2.console.aws.amazon.com/codesuite/codebuild/638924580364/projects/grant-user-access-pr-builder/history?region=eu-west-2)
- Codepipeline pipeline config for deployment can be found in [here](https://github.com/hmrc/aws-grant-user-access/blob/main/terraform/ci/pipeline/terragrunt.hcl)

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
<ENV>_ACCOUNT_ID=123456789012 \
  make bootstrap-${ENV}
```

## How do I plan/apply terraform to an environment?

There is [CI/CD pipeline](#cicd-pipeline) in place to test and apply new changes. However, in the event there is a
need to run/test applying terraform resources locally use the command below

```bash
<ENV>_ACCOUNT_ID=123456789012 \
  make ${CMD}-${ENV}

# where CMD is one of: validate, plan or apply
# e.g. LABS_ACCOUNT_ID=123456789012 make plan-labs
```

## Setting up locally

Pre-requisites:
- [aws-vault tool](https://github.com/99designs/aws-vault#installing)
- Terraform
- Terragrunt

### Running the code: Terragrunt

Before installing or running anything please read this section as it contains important information regarding how we
execute Terraform.

We use [Terragrunt](#Terragrunt) as our interface to Terraform. Terragrunt is a thin wrapper around Terraform and
provides several key improvements over using Terraform directly. For example Terragrunt gives us the ability to keep
code much DRYer than otherwise possible. For more details check out the [Terragrunt website](https://terragrunt.gruntwork.io/).
By design we *do not* invoke Terraform directly, instead we invoke Terragrunt.

#### aws-vault tool

Install [aws-vault tool](https://github.com/99designs/aws-vault#installing).

```bash
brew install --cask aws-vault
```

See https://github.com/99designs/aws-vault#installing for installation steps on Linux and Windows

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
