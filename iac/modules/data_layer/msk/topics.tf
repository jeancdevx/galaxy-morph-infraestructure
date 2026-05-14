# Topic creation is currently done outside Terraform from CloudShell/CI runners
# that have network path to MSK in VPC and IAM auth for Kafka operations.
#
# resource "kafka_topic" "ingestion" {
#   name               = "galaxy.ingestion"
#   replication_factor = 2
#   partitions         = 24
#
#   config = {
#     "retention.ms" = "604800000"
#   }
# }
#
# resource "kafka_topic" "results" {
#   name               = "galaxy.results"
#   replication_factor = 2
#   partitions         = 24
#
#   config = {
#     "retention.ms" = "259200000"
#   }
# }
