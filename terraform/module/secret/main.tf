
variable "app_name" {}
variable "stage" {}
variable "secret_key" {}

resource "aws_secretsmanager_secret" "hash_secret" {
  name = "/${var.app_name}/${var.stage}/hash"
  force_overwrite_replica_secret = true
}

resource "aws_secretsmanager_secret_version" "hash_secret_version" {
  secret_id = aws_secretsmanager_secret.hash_secret.id
  secret_string = jsonencode({
    secret_key = var.secret_key
  })
}
