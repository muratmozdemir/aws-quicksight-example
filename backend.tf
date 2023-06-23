# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

# The block below configures Terraform to use the 'remote' backend with Terraform Cloud.
# For more information, see https://www.terraform.io/docs/backends/types/remote.html
terraform {
  cloud {
    organization = "muratmozdemir"

    workspaces {
      name = "aws-quicksight-example"
    }
  }

  required_providers {
    aws-test = {
      source  = "BigEyeLabs/aws-test"
      version = ">= 5.4.2"
      # configuration_aliases = [ aws-test.aws ]
    }
  }

  required_version = ">= 1.4.6"
}
