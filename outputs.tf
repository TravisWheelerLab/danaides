output "sqs_url" {
  value = module.app.sqs_url
}

output "efs_arn" {
  value = module.app.efs_arn
}

output "bastion_instance_ip" {
  value = module.bastion.bastion_instance_ip
}
