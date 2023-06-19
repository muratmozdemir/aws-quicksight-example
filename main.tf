data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

output "account_id" {
  value = local.account_id
}

# S3 Buckets
resource "aws_s3_bucket" "students_bucket" {
  bucket = "students-data-${local.account_id}"
  force_destroy = true
}

resource "aws_s3_bucket" "athena_query_results_bucket" {
  bucket = "athena-queryresults-students-${local.account_id}"
  force_destroy = true
}

# Parquet Files
resource "aws_s3_object" "students_parquet_file" {
  bucket = aws_s3_bucket.students_bucket.id
  key    = "students/students.parquet"
  source = "${path.module}/data/students.parquet"
  etag   = filemd5("${path.module}/data/students.parquet")
}

resource "aws_s3_object" "enrollments_parquet_file" {
  bucket = aws_s3_bucket.students_bucket.id
  key    = "enrollments/enrollments.parquet"
  source = "${path.module}/data/enrollments.parquet"
  etag   = filemd5("${path.module}/data/enrollments.parquet")
}

# Glue Databases
resource "aws_glue_catalog_database" "students_db" {
  name = "students_db"
}

resource "aws_glue_catalog_database" "enrollments_db" {
  name = "enrollments_db"
}

# Athena Workgroup
resource "aws_athena_workgroup" "students_athena_workgroup" {
  name        = "students-wg"
  description = "Example hello world workgroup"

  configuration {
    enforce_workgroup_configuration = true

    result_configuration {
      encryption_configuration {
        encryption_option = "SSE_S3"
      }

      output_location = "s3://${aws_s3_bucket.athena_query_results_bucket.bucket}/"
    }
  }
}

# Glue "Physical" Tables
resource "aws_glue_catalog_table" "students_table" {
  name          = "students"
  database_name = aws_glue_catalog_database.students_db.name

  table_type = "EXTERNAL_TABLE"

  parameters = {
    EXTERNAL              = "TRUE"
    "parquet.compression" = "SNAPPY"
  }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.students_bucket.bucket}/students"
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"

    ser_de_info {
      name                  = "my-stream"
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"

      parameters = {
        "serialization.format" = 1
      }
    }

    columns {
      name = "id"
      type = "bigint"
    }

    columns {
      name = "name"
      type = "string"
    }

    columns {
      name = "favorite_color"
      type = "string"
    }

    columns {
      name = "favorite_programming_language"
      type = "string"
    }

    columns {
      name = "country"
      type = "string"
    }
  }
  depends_on = [aws_s3_object.students_parquet_file]
}

resource "aws_glue_catalog_table" "enrollments_table" {
  name          = "enrollments"
  database_name = aws_glue_catalog_database.enrollments_db.name

  table_type = "EXTERNAL_TABLE"

  parameters = {
    EXTERNAL              = "TRUE"
    "parquet.compression" = "SNAPPY"
  }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.students_bucket.bucket}/enrollments"
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"

    ser_de_info {
      name                  = "my-stream"
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"

      parameters = {
        "serialization.format" = 1
      }
    }

    columns {
      name = "student_id"
      type = "bigint"
    }

    columns {
      name = "enrolled_class"
      type = "string"
    }
  }

  depends_on = [aws_s3_object.enrollments_parquet_file]
}

# Glue Table "Views"
resource "aws_glue_catalog_table" "student_summary_view" {
  database_name = aws_glue_catalog_database.students_db.name
  name          = "student_summary"

  table_type         = "VIRTUAL_VIEW"
  view_original_text = "/* Presto View: ${base64encode(file("${path.module}/data/views/student_summary.json"))} */"
  view_expanded_text = "/* Presto View */"

  parameters = {
    presto_view = "true"
    comment     = "Presto View"
  }

  storage_descriptor {
    ser_de_info {
      name                  = "ParquetHiveSerDe"
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
    }

    columns {
      name = "id"
      type = "bigint"
    }
    columns {
      name = "name"
      type = "string"
    }
    columns {
      name = "favorite_color"
      type = "string"
    }

    columns {
      name = "country"
      type = "string"
    }
  }
  depends_on = [aws_glue_catalog_table.students_table, aws_glue_catalog_table.enrollments_table]
}

resource "aws_glue_catalog_table" "enrollments_view" {
  database_name = aws_glue_catalog_database.students_db.name
  name          = "enrollments"

  table_type         = "VIRTUAL_VIEW"
  view_original_text = "/* Presto View: ${base64encode(file("${path.module}/data/views/enrollments.json"))} */"
  view_expanded_text = "/* Presto View */"

  parameters = {
    presto_view = "true"
    comment     = "Presto View"
  }

  storage_descriptor {
    ser_de_info {
      name                  = "ParquetHiveSerDe"
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
    }

    columns {
      name = "student_id"
      type = "bigint"
    }
    columns {
      name = "enrolled_class"
      type = "string"
    }
  }

  depends_on = [aws_glue_catalog_table.students_table, aws_glue_catalog_table.enrollments_table]
}

# QuickSight DataSource
resource "aws_quicksight_data_source" "students_athena_data_source" {
  aws_account_id = local.account_id
  data_source_id = aws_athena_workgroup.students_athena_workgroup.name
  name           = aws_athena_workgroup.students_athena_workgroup.name
  type           = "ATHENA"

  parameters {
    athena {
      work_group = aws_athena_workgroup.students_athena_workgroup.id
    }
  }

  permission {
    actions = [
      "quicksight:DescribeDataSource",
      "quicksight:DescribeDataSourcePermissions",
      "quicksight:PassDataSource",
      "quicksight:UpdateDataSource",
      "quicksight:DeleteDataSource",
      "quicksight:UpdateDataSourcePermissions"
    ]
    principal = "arn:aws:quicksight:us-east-1:363873625167:user/default/AdministratorAccess/mozdemir"
  }
}

# QuickSight Dataset [BUG]: The JSON generated by Terraform for `data_transforms` is incorrect, therefore an error is returned.
resource "aws_quicksight_data_set" "student_summary_view_dataset" {
  data_set_id = "826896be-4d0f-4f90-832f-3427f5444016"
  name        = "student_summary_view"
  import_mode = "SPICE"

  physical_table_map {
    physical_table_map_id = "616bd20f-660c-49e0-95d3-0b5d21ef39f1"
    relational_table {
      data_source_arn = aws_quicksight_data_source.students_athena_data_source.arn
      schema          = aws_glue_catalog_database.students_db.name
      name            = aws_glue_catalog_table.student_summary_view.name

      input_columns {
        name = "id"
        type = "INTEGER"
      }

      input_columns {
        name = "name"
        type = "STRING"
      }

      input_columns {
        name = "favorite_color"
        type = "STRING"
      }

      input_columns {
        name = "favorite_programming_language"
        type = "STRING"
      }

      input_columns {
        name = "country"
        type = "STRING"
      }
    }
  }
  physical_table_map {
    physical_table_map_id = "7bb99428-5dfd-4599-8893-b4f57f0c689f"
    relational_table {
      data_source_arn = aws_quicksight_data_source.students_athena_data_source.arn
      schema          = aws_glue_catalog_database.students_db.name
      name            = aws_glue_catalog_table.enrollments_view.name

      input_columns {
        name = "id"
        type = "INTEGER"
      }

      input_columns {
        name = "enrolled_class"
        type = "STRING"
      }
    }
  }

  logical_table_map {
    logical_table_map_id = "4529aa95-4a51-4938-820b-5fd03af630e1"
    alias                = aws_glue_catalog_table.student_summary_view.name
    source {
      physical_table_id = "616bd20f-660c-49e0-95d3-0b5d21ef39f1"
    }
  }

  logical_table_map {
    logical_table_map_id = "6beb277c-4d74-47da-b425-1e255aa31bd1"
    alias                = "Intermediate Table"
    data_transforms {
      project_operation {
        projected_columns = [
          "id",
          "name",
          "favorite_color",
          "country",
          "student_id",
          "enrolled_class"
        ]
      }
      tag_column_operation {
        column_name = "country"
        tags {
          column_geographic_role = "STATE"
        }
      }
    }
    source {
      join_instruction {
        left_operand  = "4529aa95-4a51-4938-820b-5fd03af630e1"
        right_operand = "1a0d1482-1bf2-46ee-8dc4-5aaea2ab2231"
        type          = "LEFT"
        on_clause     = "{id} = {student_id}"
      }
    }
  }

  logical_table_map {
    logical_table_map_id = "1a0d1482-1bf2-46ee-8dc4-5aaea2ab2231"
    alias                = aws_glue_catalog_table.enrollments_view.name
    source {
      physical_table_id = "7bb99428-5dfd-4599-8893-b4f57f0c689f"
    }
  }

  permissions {
    actions = [
      "quicksight:ListIngestions",
      "quicksight:DeleteDataSet",
      "quicksight:UpdateDataSetPermissions",
      "quicksight:CancelIngestion",
      "quicksight:DescribeDataSetPermissions",
      "quicksight:UpdateDataSet",
      "quicksight:DescribeDataSet",
      "quicksight:PassDataSet",
      "quicksight:DescribeIngestion",
      "quicksight:CreateIngestion"
    ]
    principal = "arn:aws:quicksight:us-east-1:363873625167:user/default/AdministratorAccess/mozdemir"
  }

  depends_on = [ aws_glue_catalog_table.student_summary_view, aws_glue_catalog_table.enrollments_view ]
}
