variable "waf_name" {
  description = "Enter the name of the WAF:"
  type = string
  
}

variable "bucket_name" {
  description = "Enter name of the S3 bucket (lowercase, no special characters, and no spaces):"
}

variable "codepipeline_name" {
  description = "Enter the name of the CodePipeline:"
  type = string
}

variable "codepipeline_connection_name" {
  description = "Enter the connection name of the CodePipeline to/from Github:"
  type = string
}

variable "github_repo_name" {
  description = "Enter the name of the GitHub repository (username/repo):"
  type = string
  
}

variable "acm_aws_domain_name" {
  description = "Enter the domain name for ACM (no subdomain):"
  type = string
  
}

variable "acm_alt_aws_domain_name" {
  description = "Enter the alternative domain names for ACM (subdomains): Example: [\"subdomain1.domain.com\", \"subdomain2.domain.com\"]"
  type        = list(string)
}


variable "cloudfront_domain" {
  description = "Enter the domain name to use for the Cloudfront distribution and Route53 (no subdomain):"
  type = string
}

variable "cloudfront_alt_domain" {
  description = "Enter the alternative domain name to use for the Cloudfront distribution and Route53 (subdomains):"
  type = string
}

variable "aws_zone_id" {
  description = "Enter the Route 53 zone ID"
  type = string
  sensitive = true
  
}

