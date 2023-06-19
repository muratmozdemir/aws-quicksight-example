provider "aws" {
    assume_role {
        role_arn     = var.AWS_ASSUME_ROLE_ARN
    }
}
