# Athena のクエリ結果出力用バケット
resource "aws_s3_bucket" "athena_results" {
  bucket        = "${data.aws_caller_identity.current.account_id}-level2-athena-results"
  force_destroy = true
}

# Glue データベース（BigQueryの「データセット」に相当）
resource "aws_glue_catalog_database" "ecommerce" {
  name = "ecommerce"
}

# Glue テーブル（S3上のJSONにスキーマを与える）
resource "aws_glue_catalog_table" "orders" {
  name          = "orders"
  database_name = aws_glue_catalog_database.ecommerce.name
  table_type    = "EXTERNAL_TABLE"

  parameters = {
    classification = "json"
  }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.data.bucket}/orders/"
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
      name = "amount"
      type = "double"
    }
    columns {
      name = "items"
      type = "string"
    }
    columns {
      name = "created_at"
      type = "string"
    }
  }
}

resource "aws_athena_workgroup" "ecommerce" {
  name          = "level2-workgroup"
  force_destroy = true

  configuration {
    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_results.bucket}/"
    }
  }
}
