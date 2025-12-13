# output "vpc_id" {
#   value = module.vpc.vpc_id
# }

# output "eks_cluster_name" {
#   value = module.eks.cluster_name
# }

output "data_bucket_name" {
  value = module.data_bucket.bucket_name
}
