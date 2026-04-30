resource "aws_s3_bucket" "raw_bucket" {
  bucket = var.raw_bucket_name
  
  tags = {
    Name = var.raw_bucket_name
  }
}

resource "aws_s3_object" "sqs_plugin" {
  bucket     = aws_s3_bucket.raw_bucket.id
  key        = "plugins/sqs-source-plugin.zip"
  source     = "${path.module}/../../../../build/sqs-source-plugin.zip"
  depends_on = [aws_s3_bucket.raw_bucket]

  # Force update if the file changes
  etag = filemd5("${path.module}/../../../../build/sqs-source-plugin.zip")
}

resource "aws_mskconnect_custom_plugin" "sqs_source" {
  name         = "camel-sqs-source-plugin"
  content_type = "ZIP"

  location {
    s3 {
      bucket_arn = var.raw_bucket_arn
      file_key   = aws_s3_object.sqs_plugin.key
    }
  }

  description = "Apache Camel SQS Source Connector for MSK Connect"
}
