output "bucket_name" {
  value = aws_s3_bucket.data.bucket
}
output "bucket_arn" {
  value = aws_s3_bucket.data.arn
}
output "iam_access_key_id" {
  value     = aws_iam_access_key.ingest_user_key.id
  sensitive = true
}
output "iam_secret_access_key" {
  value     = aws_iam_access_key.ingest_user_key.secret
  sensitive = true
}
