# Terraform AWS QuickSight and Athena Setup

This repository contains a Terraform module that sets up an AWS data pipeline with S3 buckets, Glue Catalogs, Athena Workgroup and Tables, and QuickSight data sources and datasets.

This is a very simple example repository only to demonstrate how to configure these resources in AWS with Terraform using Parquet files.

## Resources

The Terraform script will setup the following resources:

- AWS S3 Buckets for storing student and enrollment parquet files, as well as Athena query results.
- AWS Glue Catalog Databases for students and enrollments.
- AWS Glue Catalog Tables for student and enrollment data, as well as views based on these tables.
- An AWS Athena Workgroup for executing queries against our data.
- AWS QuickSight data sources and datasets for visualizing our data.

## File Structure

- `main.tf` : This file contains the Terraform script to set up the AWS resources.
- `resources` : This directory contains the Parquet files for student and enrollment data.

## Usage

1. Ensure that you have the correct AWS credentials set up on your machine. This module will use your default AWS credentials. 
   You can set up your AWS credentials by following the instructions [here](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html).

2. Install Terraform on your machine if you haven't done so already. You can download Terraform [here](https://www.terraform.io/downloads.html).

3. Navigate to the directory containing the Terraform script and initialize Terraform:

    ```
    terraform init
    ```

4. Preview the changes to be made by Terraform:

    ```
    terraform plan
    ```

5. If you're happy with the changes, apply them:

    ```
    terraform apply
    ```

## Important Note

- Be aware that AWS charges for the use of these services. Be sure to destroy the Terraform resources when you're done using them to avoid unnecessary costs:

    ```
    terraform destroy
    ```

## License

This project is licensed under the MIT License - see the LICENSE.md file for details
