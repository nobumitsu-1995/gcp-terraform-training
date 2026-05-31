# 加工済みデータの保存先（Athena 分析対象）
resource "aws_s3_bucket" "processed" {
  bucket        = "${data.aws_caller_identity.current.account_id}-level3-processed"
  force_destroy = true
}

# Athena のクエリ結果出力用
resource "aws_s3_bucket" "athena_results" {
  bucket        = "${data.aws_caller_identity.current.account_id}-level3-athena-results"
  force_destroy = true
}

resource "aws_glue_catalog_database" "analytics" {
  name = "level3_analytics"
}

resource "aws_glue_catalog_table" "orders" {
  name          = "orders"
  database_name = aws_glue_catalog_database.analytics.name
  table_type    = "EXTERNAL_TABLE"

  parameters = {
    classification = "json"
  }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.processed.bucket}/orders/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      serialization_library = "org.openx.data.jsonserde.JsonSerDe"
    }

    columns {
      name = "order_id"
      type = "string"
    }
    columns {
      name = "customer"
      type = "string"
    }
    columns {
      name = "product"
      type = "string"
    }
    columns {
      name = "amount"
      type = "double"
    }
    columns {
      name = "status"
      type = "string"
    }
    columns {
      name = "created_at"
      type = "string"
    }
  }
}

resource "aws_athena_workgroup" "main" {
  name          = "level3-workgroup"
  force_destroy = true

  configuration {
    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_results.bucket}/"
    }
  }
}
