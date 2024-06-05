output "bastion_instance_ip" {
  description = "The public IP address of the Bastion instance"
  value       = aws_instance.bastion.public_ip
}
