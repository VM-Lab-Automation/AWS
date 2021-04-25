resource "aws_s3_bucket" "packer" {
  bucket = "packer-ami"
  acl    = "private"

  tags = {
    Name        = "Packer"
  }
}

data "aws_iam_role" "vmimport" {
  name = "vmimport"
  
  assume_role_policy = jsonencode({
   Version = "2012-10-17",
   Statement = [
      {
         Effect = "Allow",
         Principal = { 
			Service =  "vmie.amazonaws.com" 
		},
         Action = "sts:AssumeRole",
         Condition = {
            StringEquals = {
               "sts:Externalid" =  "vmimport"
            }
         }
      }
   ]
  })
}

resource "aws_iam_role_policy" "vmimport_policy" {
  name = "test_policy"
  role = aws_iam_role.test_role.id

  policy = jsonencode({
   Version = "2012-10-17",
   Statement = [
      {
         Effect = "Allow",
         Action = [
            "s3:GetBucketLocation",
            "s3:GetObject",
            "s3:ListBucket" 
         ],
         Resource = [
            "arn:aws:s3:::${var.aws_s3_bucket.packer.name}",
            "arn:aws:s3:::${var.aws_s3_bucket.packer.name}/*"
         ]
      },
      {
         Effect = "Allow",
         Action = [
            "s3:GetBucketLocation",
            "s3:GetObject",
            "s3:ListBucket",
            "s3:PutObject",
            "s3:GetBucketAcl"
         ],
         Resource = [
            "arn:aws:s3:::${var.aws_s3_bucket.packer.name}",
            "arn:aws:s3:::${var.aws_s3_bucket.packer.name}/*"
         ]
      },
      {
         Effect = "Allow",
         Action = [
            "ec2:ModifySnapshotAttribute",
            "ec2:CopySnapshot",
            "ec2:RegisterImage",
            "ec2:Describe*"
         ],
         Resource = "*"
      }
   ]
  })
}

resource "aws_iam_role_policy_attachment" "test-attach" {
  role       = aws_iam_role.vmimport.name
  policy_arn = aws_iam_policy.vmimport_policy.arn
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}
