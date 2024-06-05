data "aws_ami" "amazon_linux_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023*"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_key_pair" "mykeypair" {
  key_name   = "mykeypair"
  public_key = file(var.public_key)
}

resource "aws_security_group" "bastion-allow-ssh" {
  vpc_id      = var.vpc_id
  name        = "bastion-allow-ssh"
  description = "security group for bastion that allows ssh and all egress traffic"
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "bastion-allow-ssh"
  }
}

resource "aws_security_group" "private-ssh" {
  vpc_id      = var.vpc_id
  name        = "private-ssh"
  description = "security group for private that allows ssh and all egress traffic"
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion-allow-ssh.id]
  }
  tags = {
    Name = "private-ssh"
  }
}

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.amazon_linux_ami.id
  instance_type               = "t2.micro"
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [aws_security_group.bastion-allow-ssh.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.mykeypair.key_name
}

resource "aws_instance" "private" {
  ami                    = data.aws_ami.amazon_linux_ami.id
  instance_type          = "t2.micro"
  subnet_id              = var.private_subnet_id
  vpc_security_group_ids = [aws_security_group.private-ssh.id]
  key_name               = aws_key_pair.mykeypair.key_name
  # user_data              = data.template_file.user_data.rendered
  user_data = <<-EOF
          #! /bin/bash
          echo "test file" >> /tmp/test.txt

          sudo yum -y update
          sudo yum reboot

          # Install nfs client
          sudo yum -y install nfs-utils

          # Mount the EFS 
          mkdir efs
          sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${var.efs_dns_name} efs

          cd efs
      EOF
}

resource "null_resource" "keys_to_ec2_bastion_instance" {
  connection {
    type        = "ssh"
    host        = aws_instance.bastion.public_ip
    user        = "ec2-user"
    password    = ""
    private_key = file(var.private_key)
  }

  provisioner "file" {
    source      = var.private_key
    destination = "/tmp/.bastion_key" # TODO: Make this a variable
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod 400 /tmp/.bastion_key", # TODO: Change this to a more secure location
    ]
  }

  depends_on = [aws_instance.bastion]
}
