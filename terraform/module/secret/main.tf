
variable "app_name" {}
variable "stage" {}
variable "secret_key" {}

resource "aws_secretsmanager_secret" "jwt_secret" {
  name = "/${var.app_name}/${var.stage}/jwt"
  recovery_window_in_days = 0
  force_overwrite_replica_secret = true
}

resource "aws_secretsmanager_secret_version" "hash_secret_version" {
  secret_id = aws_secretsmanager_secret.jwt_secret.id
  secret_string = jsonencode({
    secret_key = var.secret_key
  })
}
