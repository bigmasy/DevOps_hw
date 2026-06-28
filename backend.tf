terraform {
  backend "s3" {
    bucket         = "terraform-state-bucket-lesson7-qvnkd"
    key            = "lesson-7/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-locks-lesson7"
    encrypt        = true
  }
}