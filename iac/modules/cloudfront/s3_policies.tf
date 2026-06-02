data "aws_iam_policy_document" "spa_oac" {
  statement {
    sid = "AllowCloudFrontOAC"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions   = ["s3:GetObject"]
    resources = ["${var.spa_bucket_arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.this.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "spa" {
  bucket = var.spa_bucket_id
  policy = data.aws_iam_policy_document.spa_oac.json
}

data "aws_iam_policy_document" "images_oac" {
  statement {
    sid = "AllowCloudFrontOAC"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions   = ["s3:GetObject"]
    resources = ["${var.images_bucket_arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.this.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "images" {
  bucket = var.images_bucket_id
  policy = data.aws_iam_policy_document.images_oac.json
}
