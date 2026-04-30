# resource "kafka_topic" "ingestion" {
#  name               = "galaxy.ingestion"
#   replication_factor = 3
#   partitions         = 50
# 
#   config = {
#     "retention.ms" = "604800000"
#   }
# }
# 
# resource "kafka_topic" "results" {
#   name               = "galaxy.results"
#   replication_factor = 3
#   partitions         = 50
# 
#   config = {
#     "retention.ms" = "259200000"
#   }
# }
