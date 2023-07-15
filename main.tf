terraform {
  backend "s3" {
    bucket         = "k3s-cluster-provision"
    key            = "terraform/state.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-table" 
    encrypt        = true 
  }
}

resource "aws_instance" "master" {
  ami             = var.ami
  instance_type   = var.instance_type
  key_name        = var.key_name
  subnet_id       = aws_subnet.cluster_subnet.id
  security_groups = [aws_security_group.cluster_sg.id]

  tags = {
    Name = "master"
  }

  provisioner "remote-exec" {
    inline = [
      "curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=\"v1.25.5+k3s1\" sh -s - server --token=MyCustomTokenForK3s"
    ]
  }

  connection {
    type        = "ssh"
    host        = aws_instance.master.public_ip
    user        = "ubuntu"
    private_key = tls_private_key.ssh_key_aws.private_key_pem
  }

}

resource "aws_instance" "nodes" {
  count = 2

  ami             = var.ami
  instance_type   = var.instance_type
  key_name        = var.key_name
  subnet_id       = aws_subnet.cluster_subnet.id
  security_groups = [aws_security_group.cluster_sg.id]

  tags = {
    Name = "node-${count.index + 1}"
  }
  connection {
    type        = "ssh"
    user        = "ubuntu" 
    private_key = tls_private_key.ssh_key_aws.private_key_pem
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION='v1.25.5+k3s1' sh -s - agent --server https://${aws_instance.master.private_ip}:6443 --token=MyCustomTokenForK3s"
    ]
  }
}
