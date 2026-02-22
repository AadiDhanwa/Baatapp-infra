output "redis_endpoint" {
  value = aws_elasticache_cluster.redis.cache_nodes[0].address
}

output "rds_endpoint" {
  value = aws_db_instance.chatdb.endpoint
}