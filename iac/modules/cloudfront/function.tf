resource "aws_cloudfront_function" "api_rewrite" {
  name    = "${var.name_prefix}-api-rewrite"
  runtime = "cloudfront-js-2.0"
  comment = "Strip /api prefix before forwarding to API Gateway"
  publish = true

  code = <<-JS
    function handler(event) {
      let request = event.request;
      // Remove the leading /api so /api/v1/x becomes /v1/x
      request.uri = request.uri.replace(/^\/api/, '');
      return request;
    }
  JS
}
