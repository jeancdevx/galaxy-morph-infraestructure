output "custom_domain_name" {
  description = "Custom domain name registered with AppSync (e.g. api.galaxymorph.com)"
  value       = aws_appsync_domain_name.this.domain_name
}

output "appsync_domain_name" {
  description = "Internal AppSync-managed CloudFront domain name (target of the Route53 alias)"
  value       = aws_appsync_domain_name.this.appsync_domain_name
}

output "graphql_url" {
  description = "Custom domain GraphQL endpoint"
  value       = "https://${aws_appsync_domain_name.this.domain_name}/graphql"
}

output "realtime_url" {
  description = "Custom domain WebSocket (real-time) endpoint"
  value       = "wss://${aws_appsync_domain_name.this.domain_name}/graphql/realtime"
}
