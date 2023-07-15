resource "tls_private_key" "ssh_key_aws" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

locals {
  private_key_file = "private_key.pem"
}

resource "local_file" "aws_private_key" {
  content  = tls_private_key.ssh_key_aws.private_key_pem
  filename = local.private_key_file
}

resource "aws_key_pair" "mykey" {
  key_name   = "mykey"
  public_key = tls_private_key.ssh_key_aws.public_key_openssh
}

resource "aws_s3_object" "instance_key" {
  bucket = "k3s-cluster-provision"
  key    = "cluster/${local.private_key_file}"
  source = local.private_key_file
  depends_on = [aws_key_pair.mykey]
}
