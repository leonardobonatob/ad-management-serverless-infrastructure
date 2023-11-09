#Lambda output
output "lambda" {
  value = aws_lambda_function.lambda.qualified_arn
}

output "ad_service_dns_joined" {
  value = "${join(",",aws_directory_service_directory.aws_ad.dns_ip_addresses)}"
}

output "ad_dns_name" {
  value = aws_directory_service_directory.aws_ad.name
  sensitive = true
}