
# S3
resource "aws_s3_bucket" "datalake" {
  bucket = "aebel-datalake"

  tags = {
    Name = "Datalake bucket"
  }

  force_destroy = true
}

resource "aws_s3_bucket" "athena_results" {
  bucket = "aebel-athena-results"

  tags = {
    Name = "Athena results bucket"
  }

  force_destroy = true
}


resource "aws_s3_bucket_lifecycle_configuration" "expire_temp" {
  bucket = aws_s3_bucket.datalake.bucket

  rule {
    id     = "Expire values in schema=temp/ prefix"
    status = "Enabled"
    expiration {
      days = 90
    }

    filter {
      prefix = "temp/"
    }

  }

}

resource "aws_s3_bucket_lifecycle_configuration" "expire_athena_results" {
  bucket = aws_s3_bucket.athena_results.bucket

  rule {
    id     = "Expire values in athena results bucket"
    status = "Enabled"
    expiration {
      days = 90
    }

    filter {
      prefix = ""
    }
  }

}


resource "aws_s3_object" "datalake_dbs" {
  for_each = toset(["bronze", "silver", "gold"])

  bucket = aws_s3_bucket.datalake.id
  key    = "${each.key}/.keep"
}

# Athena
resource "aws_athena_workgroup" "datalake" {
  name = "datalake"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true
    bytes_scanned_cutoff_per_query     = 10 * 1024 * 1024 * 1024

    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_results.bucket}/results/"
    }

    engine_version {
      selected_engine_version = "Athena engine version 3"
    }
  }

  force_destroy = true
}


# Glue
resource "aws_glue_catalog_database" "bronze" {
  name         = "datalake_bronze"
  location_uri = "s3://${aws_s3_bucket.datalake.bucket}/bronze"
}

resource "aws_glue_catalog_database" "silver" {
  name         = "datalake_silver"
  location_uri = "s3://${aws_s3_bucket.datalake.bucket}/silver"
}

resource "aws_glue_catalog_database" "gold" {
  name         = "datalake_gold"
  location_uri = "s3://${aws_s3_bucket.datalake.bucket}/gold"
}

resource "aws_glue_catalog_table" "noaa_ghcn_daily" {
  database_name = aws_glue_catalog_database.bronze.name
  name          = "noaa_ghcn_daily"

  table_type = "EXTERNAL_TABLE"

  parameters = {
    EXTERNAL              = "TRUE"
    "parquet.compression" = "SNAPPY"
    # Partition projection instead of msck repair table: msck skips non-lowercase keys (YEAR=, ELEMENT=),
    # while the location template maps onto the uppercase NOAA layout as-is.
    # element is "injected" as there are many values, so queries must filter on element (= or IN).
    "projection.enabled"        = "true"
    "projection.year.type"      = "integer"
    "projection.year.range"     = "1750,2100"
    "projection.element.type"   = "injected"
    "storage.location.template" = "s3://${aws_s3_bucket.datalake.bucket}/bronze/noaa_ghcn_daily/YEAR=$${year}/ELEMENT=$${element}/"
  }

  storage_descriptor {
    location      = "${aws_glue_catalog_database.bronze.location_uri}/noaa_ghcn_daily"
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"

    ser_de_info {
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
    }

    # Instead of relying on crawler to define column, lets define it ourselves. This is simple enough
    columns {
      name = "ID"
      type = "string"
    }

    columns {
      name = "DATE"
      type = "string"
    }

    columns {
      name = "DATA_VALUE"
      type = "int"
    }

    columns {
      name = "M_FLAG"
      type = "string"
    }

    columns {
      name = "Q_FLAG"
      type = "string"
    }

    columns {
      name = "S_FLAG"
      type = "string"
    }

    columns {
      name = "OBS_TIME"
      type = "string"
    }

  }
  partition_keys {
    name = "YEAR"
    type = "int"
  }

  partition_keys {
    name = "ELEMENT"
    type = "string"
  }
}
