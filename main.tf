resource "aws_s3_bucket" "datalake" {
  bucket = "aebel-datalake"

  tags = {
    Name = "Datalake bucket"
  }
  

  force_destroy = true
}


resource "aws_s3_bucket_lifecycle_configuration" "datalake" {
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

resource "aws_s3_object" "datalake_dbs" {
  for_each = toset(["bronze", "silver", "gold", "temp"])

  bucket  = aws_s3_bucket.datalake.id
  key      = "${each.key}/.keep"
}