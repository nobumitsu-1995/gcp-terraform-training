# 分析対象データを置く S3 バケット
resource "aws_s3_bucket" "data" {
  bucket        = "${data.aws_caller_identity.current.account_id}-events-data"
  force_destroy = true
}

# Athena のクエリ結果出力用バケット
resource "aws_s3_bucket" "athena_results" {
  bucket        = "${data.aws_caller_identity.current.account_id}-athena-results"
  force_destroy = true
}

# Glue データカタログのデータベース（BigQueryの「データセット」に相当）
resource "aws_glue_catalog_database" "events" {
  name = "events_db"
}

# Glue テーブル（S3上のJSONにスキーマを与える）
resource "aws_glue_catalog_table" "events" {
  name          = "events"
  database_name = aws_glue_catalog_database.events.name
  table_type    = "EXTERNAL_TABLE"

  parameters = {
    classification = "json"
  }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.data.bucket}/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      serialization_library = "org.openx.data.jsonserde.JsonSerDe"
    }

    columns {
      name = "name"
      type = "string"
    }
    columns {
      name = "value"
      type = "int"
    }
    columns {
      name = "received_at"
      type = "string"
    }
  }
}

# Athena ワークグループ（クエリ結果の出力先を指定）
resource "aws_athena_workgroup" "events" {
  name          = "events-workgroup"
  force_destroy = true

  configuration {
    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_results.bucket}/"
    }
  }
}
