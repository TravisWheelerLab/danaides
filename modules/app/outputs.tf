output "sqs_url" {
  value = aws_sqs_queue.data_queue.url
}

output "efs_arn" {
  value = aws_efs_file_system.efs.arn
}

output "efs_dns_name" {
  value = aws_efs_file_system.efs.dns_name
}
