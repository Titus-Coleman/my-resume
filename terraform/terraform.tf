terraform {
  backend "s3" {
    bucket  = "my-resume-terraform-state"
    profile = "default"
    region  = "us-east-1"
  }
}
