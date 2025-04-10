terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.77.0"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  alias = "us_west_2" # Change this to your preferred alias
  region  = "us-west-2" # Change this to your preferred region
  profile = "default"
}

provider "aws" {
  alias   = "us_east_1" # Change this to your preferred alias
  region  = "us-east-1" # Change this to your preferred region
}

provider "aws" {
  alias   = "global" # Change this to your preferred alias
  region  = "us-east-1" # Change this to your preferred region
}