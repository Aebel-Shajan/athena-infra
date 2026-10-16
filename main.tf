
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

  bucket  = aws_s3_bucket.datalake.id
  key      = "${each.key}/.keep"
}

# Athena
resource "aws_athena_workgroup" "datalake" {
  name = "datalake"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true
    bytes_scanned_cutoff_per_query = 10 * 1024 * 1024 * 1024

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
  name = "datalake_bronze"
  location_uri ="s3://${aws_s3_bucket.datalake.bucket}/bronze"
}

resource "aws_glue_catalog_database" "silver" {
  name = "datalake_silver"
  location_uri ="s3://${aws_s3_bucket.datalake.bucket}/silver"
}

resource "aws_glue_catalog_database" "gold" {
  name = "datalake_gold"
  location_uri ="s3://${aws_s3_bucket.datalake.bucket}/gold"
}