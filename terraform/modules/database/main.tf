resource "aws_kms_key" "dbkey" {
  description             = "This key is used to encrypt database storage"
  deletion_window_in_days = 10
  tags                    = merge(var.resource_tags, { Name = "${var.resource_prefix}-DB-KMS-Key" })
}

resource "aws_db_subnet_group" "default" {
  name       = "${var.resource_prefix}-dbsubnetgroup"
  subnet_ids = [var.private_subnet1_id, var.private_subnet2_id]
}

resource "aws_security_group" "dbsecgroup" {
  name        = "${var.resource_prefix}-orthdb_sg"
  description = "postgres security group"
  vpc_id      = data.aws_vpc.mainVPC.id
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.mainVPC.cidr_block]
  }
  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = [data.aws_vpc.mainVPC.cidr_block]
  }
  tags = merge(var.resource_tags, { Name = "${var.resource_prefix}-DBSecurityGroup" })
}

resource "aws_db_instance" "postgres" {
  allocated_storage                   = 5
  storage_type                        = "standard" #magnetic drive minimum 5g storage
  engine                              = "postgres"
  engine_version                      = "12.10"
  instance_class                      = "db.t2.small" # t2.micro does not support encryption at rest
  identifier                          = "${var.resource_prefix}-orthancpostgres"
  db_name                             = "orthancdb"
  username                            = local.db_creds.username
  password                            = local.db_creds.password
  port                                = "5432"
  deletion_protection                 = false
  skip_final_snapshot                 = "true"
  iam_database_authentication_enabled = true
  final_snapshot_identifier           = "demodb"
  vpc_security_group_ids              = [aws_security_group.dbsecgroup.id]
  db_subnet_group_name                = aws_db_subnet_group.default.name
  storage_encrypted                   = true
  kms_key_id                          = aws_kms_key.dbkey.arn
  tags                                = merge(var.resource_tags, { Name = "${var.resource_prefix}-DBInstance" })
}

