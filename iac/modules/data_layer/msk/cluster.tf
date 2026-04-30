resource "aws_msk_serverless_cluster" "this" {
  cluster_name = local.cluster_name

  client_authentication {
    sasl {
      iam {
        enabled = true
      }
    }
  }

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.msk_security_group_id]
  }

  tags = {
    Name = local.cluster_name
    Tier = "data"
  }
}
