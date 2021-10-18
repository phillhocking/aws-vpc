module "vpc" {
  source       = "./vpc"
  vpc_name     = "aws-main-vpc"
  cidr_block   = "10.25.0.0/16"
  subnet_count = 1
}
