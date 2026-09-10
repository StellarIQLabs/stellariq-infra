data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs            = slice(data.aws_availability_zones.available.names, 0, var.az_count)
  public_cidrs   = [for i in range(var.az_count) : cidrsubnet(var.vpc_cidr, 8, i)]
  private_cidrs  = [for i in range(var.az_count) : cidrsubnet(var.vpc_cidr, 8, i + 100)]
  database_cidrs = [for i in range(var.az_count) : cidrsubnet(var.vpc_cidr, 8, i + 200)]
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "${var.name_prefix}-vpc" }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.name_prefix}-igw" }
}

resource "aws_subnet" "public" {
  count                   = var.az_count
  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.public_cidrs[count.index]
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name                     = "${var.name_prefix}-public-${count.index}"
    "kubernetes.io/role/elb" = "1"
  }
}

resource "aws_subnet" "private" {
  count             = var.az_count
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.private_cidrs[count.index]
  availability_zone = local.azs[count.index]

  tags = {
    Name                              = "${var.name_prefix}-private-${count.index}"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

resource "aws_subnet" "database" {
  count             = var.az_count
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.database_cidrs[count.index]
  availability_zone = local.azs[count.index]

  tags = { Name = "${var.name_prefix}-db-${count.index}" }
}

resource "aws_eip" "nat" {
  count  = var.az_count
  domain = "vpc"
  tags   = { Name = "${var.name_prefix}-nat-${count.index}" }
}

resource "aws_nat_gateway" "main" {
  count         = var.az_count
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  tags          = { Name = "${var.name_prefix}-nat-${count.index}" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = { Name = "${var.name_prefix}-public-rt" }
}

resource "aws_route_table_association" "public" {
  count          = var.az_count
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  count  = var.az_count
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }
  tags = { Name = "${var.name_prefix}-private-rt-${count.index}" }
}

resource "aws_route_table_association" "private" {
  count          = var.az_count
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# --- Security groups: strict isolation ---

# EKS nodes / app workloads
resource "aws_security_group" "app" {
  name_prefix = "${var.name_prefix}-app-"
  description = "StellarIQ application workloads"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name_prefix}-app-sg" }
}

# PostgreSQL: only reachable from app SG
resource "aws_security_group" "database" {
  name_prefix = "${var.name_prefix}-db-"
  description = "PostgreSQL - app SG only"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Postgres from app"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  tags = { Name = "${var.name_prefix}-db-sg" }
}

# Redis: only reachable from app SG
resource "aws_security_group" "redis" {
  name_prefix = "${var.name_prefix}-redis-"
  description = "Redis - app SG only"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Redis from app"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  tags = { Name = "${var.name_prefix}-redis-sg" }
}
