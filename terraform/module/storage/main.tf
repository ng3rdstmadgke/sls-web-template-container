variable "app_name" {}
variable "stage" {}
variable "vpc_id" {}
variable "subnets" {
  type = list
}
variable "db_name" {}
variable "db_user" {}
variable "db_password" {}

output "db_endpoint" {
  value = aws_db_instance.app_db.endpoint
}

#
# RDS
#
resource "aws_security_group" "app_db_sg" {
  name = "${var.app_name}-${var.stage}-db"
  vpc_id = var.vpc_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/8"]
  }
  ingress {
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    cidr_blocks = [ "10.0.0.0/8" ]
  }
}

resource "aws_db_parameter_group" "app_db_pg" {
  name = "${var.app_name}-${var.stage}-db"
  family = "mysql8.0"
  parameter {
    name = "character_set_client"
    value = "utf8mb4"
  }
  parameter {
    name = "character_set_connection"
    value = "utf8mb4"
  }
  parameter {
    name = "character_set_database"
    value = "utf8mb4"
  }
  parameter {
    name = "character_set_filesystem"
    value = "utf8mb4"
  }
  parameter {
    name = "character_set_results"
    value = "utf8mb4"
  }
  parameter {
    name = "character_set_server"
    value = "utf8mb4"
  }
  parameter {
    name = "collation_connection"
    value = "utf8mb4_bin"
  }
  parameter {
    name = "collation_server"
    value = "utf8mb4_bin"
  }
}

resource "aws_db_subnet_group" "app_db_subnet_group" {
  name       = "${var.app_name}-${var.stage}-db"
  subnet_ids = var.subnets
}

resource "aws_db_instance" "app_db" {
  identifier = "${var.app_name}-${var.stage}-db"
  storage_encrypted = true
  engine               = "mysql"
  allocated_storage    = 20
  max_allocated_storage = 100
  db_name              = var.db_name
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  db_subnet_group_name = aws_db_subnet_group.app_db_subnet_group.name
  backup_retention_period = 30
  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]
  multi_az = true
  parameter_group_name = aws_db_parameter_group.app_db_pg.name
  port = 3306
  vpc_security_group_ids = [aws_security_group.app_db_sg.id]
  storage_type = "gp3"
  network_type = "IPV4"
  username = "admin"
  password = var.db_password
  final_snapshot_identifier = "${var.app_name}-${var.stage}-db"
  deletion_protection = true
}


#
# DBのログイン情報を保持する SecretsManager
#
resource "aws_secretsmanager_secret" "app_db_secret" {
  name = "/${var.app_name}/${var.stage}/db"
  force_overwrite_replica_secret = false

}

resource "aws_secretsmanager_secret_version" "app_db_secret_version" {
  secret_id = aws_secretsmanager_secret.app_db_secret.id
  secret_string = jsonencode({
    db_user = var.db_user
    db_password = var.db_password
    db_endpoint = aws_db_instance.app_db.endpoint
  })
}
