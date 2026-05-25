output "api_id" {
  description = "AppSync GraphQL API ID"
  value       = aws_appsync_graphql_api.main.id
}

output "api_arn" {
  description = "AppSync GraphQL API ARN"
  value       = aws_appsync_graphql_api.main.arn
}

output "graphql_url" {
  description = "AppSync GraphQL endpoint URL"
  value       = aws_appsync_graphql_api.main.uris["GRAPHQL"]
}

output "realtime_url" {
  description = "AppSync real-time (WebSocket) endpoint URL"
  value       = aws_appsync_graphql_api.main.uris["REALTIME"]
}
