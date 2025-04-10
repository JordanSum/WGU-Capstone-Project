#ACM

resource "aws_acm_certificate" "acm-certificate" {
  provider          = aws.us_east_1 # ACM is only available in us-east-1
  domain_name       = var.acm_aws_domain_name
  subject_alternative_names = var.acm_alt_aws_domain_name # This is a list of alternative domain names, var.alt_aws_domain_name should be a list.
  validation_method = "DNS"


  lifecycle {
    create_before_destroy = true
  }
}

data "aws_route53_zone" "Route53-data" {
  provider = aws.us_west_2
  name         = var.acm_aws_domain_name
  private_zone = false
}

resource "aws_route53_record" "cert-validation" {
  provider = aws.us_west_2
  for_each = {
    for dvo in aws_acm_certificate.acm-certificate.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.Route53-data.zone_id
}

resource "aws_acm_certificate_validation" "certificate_validation" {
  provider = aws.us_east_1
  certificate_arn         = aws_acm_certificate.acm-certificate.arn
  validation_record_fqdns = [for record in aws_route53_record.cert-validation : record.fqdn]
}

# WAF for CloudFront

resource "aws_wafv2_web_acl" "web_acl" {
  provider = aws.global
  name        = var.waf_name
  description = "WAF ACL For CloudFront Capstone Project"
  scope       = "CLOUDFRONT"
  default_action {
    allow {}
  }

  rule {
    name     = "bad-bot-rule"
    priority = 1
    action {
      block {}
    }

    statement {
      byte_match_statement {
        search_string = "bad-bot"
        field_to_match {
          uri_path {}
        }
        text_transformation {
          priority = 0
          type     = "NONE"
        }
        positional_constraint = "CONTAINS"
      }
    }

    visibility_config {
      sampled_requests_enabled = true
      cloudwatch_metrics_enabled = true
      metric_name = "WAFMetric"
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "CloudWatchMetric"
    sampled_requests_enabled   = true
  }
}

# Cloudfront

resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for my S3 bucket"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.codepipeline_bucket.bucket_regional_domain_name
    origin_id                = aws_s3_bucket.codepipeline_bucket.bucket

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Cloudfront Distribution Project"
  default_root_object = "index.html"

  aliases = [var.cloudfront_domain, var.cloudfront_alt_domain]

  # Cache behavior with precedence 0
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.codepipeline_bucket.bucket


    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US"] # prefered location
    }
  }

  tags = {
    Environment = "development"
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.acm-certificate.arn
    ssl_support_method = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  web_acl_id = aws_wafv2_web_acl.web_acl.arn
}



resource "aws_route53_record" "cloudfront_alias" {
  zone_id = var.aws_zone_id
  name    = var.cloudfront_domain
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "cloudfront_alt_alias" {
  zone_id = var.aws_zone_id
  name    = var.cloudfront_alt_domain
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

# Codepipeline

resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_policy" "my_bucket_policy" {
  bucket = aws_s3_bucket.codepipeline_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.oai.iam_arn
        }
        Action = "s3:GetObject"
        Resource = "${aws_s3_bucket.codepipeline_bucket.arn}/*"
      }
    ]
  })
}

resource "aws_s3_bucket_public_access_block" "codepipeline_bucket_pab" {
  bucket = aws_s3_bucket.codepipeline_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_codestarconnections_connection" "git_cloud" {
  name          = var.codepipeline_connection_name
  provider_type = "GitHub"
}

resource "aws_iam_role" "codepipeline_role" {
  name = "codepipeline-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  role = aws_iam_role.codepipeline_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:*",
          "codestar-connections:UseConnection",
          "codebuild:*",
          "codepipeline:*",
          "iam:PassRole"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_codepipeline" "codepipeline" {
  name     = var.codepipeline_name
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.git_cloud.arn
        FullRepositoryId = var.github_repo_name
        BranchName       = "main"
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "S3Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "S3"
      input_artifacts = ["source_output"]
      version         = "1"

      configuration = {
        BucketName = aws_s3_bucket.codepipeline_bucket.bucket
        Extract    = "true"
      }
    }
  }
}