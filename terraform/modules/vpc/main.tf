data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  # Split VPC into /20s for subnets (enough room, easy to reason about)
  # 3 tiers x 3 AZs = 9 subnets
  public_subnet_cidrs  = [for i in range(var.az_count) : cidrsubnet(var.vpc_cidr, 4, i)]
  private_subnet_cidrs = [for i in range(var.az_count) : cidrsubnet(var.vpc_cidr, 4, i + 3)]
  db_subnet_cidrs      = [for i in range(var.az_count) : cidrsubnet(var.vpc_cidr, 4, i + 6)]

  nat_gateway_count = var.single_nat_gateway ? 1 : var.az_count
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = "${var.name}-${var.env}-vpc"
  })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name}-${var.env}-igw"
  })
}

# Public subnets
resource "aws_subnet" "public" {
  for_each                = { for idx, az in local.azs : idx => az }
  vpc_id                  = aws_vpc.this.id
  availability_zone       = each.value
  cidr_block              = local.public_subnet_cidrs[each.key]
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name                        = "${var.name}-${var.env}-public-${each.value}"
    "kubernetes.io/role/elb"    = "1"
    "Tier"                      = "public"
  })
}

# Private app subnets (EKS nodes/pods)
resource "aws_subnet" "private" {
  for_each                = { for idx, az in local.azs : idx => az }
  vpc_id                  = aws_vpc.this.id
  availability_zone       = each.value
  cidr_block              = local.private_subnet_cidrs[each.key]
  map_public_ip_on_launch = false

  tags = merge(var.tags, {
    Name                                 = "${var.name}-${var.env}-private-${each.value}"
    "kubernetes.io/role/internal-elb"    = "1"
    "Tier"                               = "private"
  })
}

# Isolated DB subnets (no route to IGW)
resource "aws_subnet" "db" {
  for_each                = { for idx, az in local.azs : idx => az }
  vpc_id                  = aws_vpc.this.id
  availability_zone       = each.value
  cidr_block              = local.db_subnet_cidrs[each.key]
  map_public_ip_on_launch = false

  tags = merge(var.tags, {
    Name  = "${var.name}-${var.env}-db-${each.value}"
    "Tier" = "db"
  })
}

# Route table for public subnets -> IGW
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name}-${var.env}-rt-public"
  })
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# NAT EIPs
resource "aws_eip" "nat" {
  count  = local.nat_gateway_count
  domain = "vpc"

  tags = merge(var.tags, {
    Name = "${var.name}-${var.env}-nat-eip-${count.index}"
  })
}

# NAT gateways live in public subnets
resource "aws_nat_gateway" "this" {
  count         = local.nat_gateway_count
  allocation_id = aws_eip.nat[count.index].id

  # if single NAT, use first public subnet; else one per AZ
  subnet_id = var.single_nat_gateway ? aws_subnet.public["0"].id : aws_subnet.public[tostring(count.index)].id

  tags = merge(var.tags, {
    Name = "${var.name}-${var.env}-nat-${count.index}"
  })

  depends_on = [aws_internet_gateway.this]
}

# Private route tables -> NAT
resource "aws_route_table" "private" {
  for_each = { for idx, az in local.azs : idx => az }
  vpc_id   = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name}-${var.env}-rt-private-${each.value}"
  })
}

resource "aws_route" "private_default" {
  for_each               = aws_route_table.private
  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"


    nat_gateway_id = (
    var.single_nat_gateway
    ? aws_nat_gateway.this[0].id
    : aws_nat_gateway.this[tonumber(each.key)].id
  )
}  


resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}

# DB route tables (NO default route to internet)
resource "aws_route_table" "db" {
  for_each = { for idx, az in local.azs : idx => az }
  vpc_id   = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name}-${var.env}-rt-db-${each.value}"
  })
}

resource "aws_route_table_association" "db" {
  for_each       = aws_subnet.db
  subnet_id      = each.value.id
  route_table_id = aws_route_table.db[each.key].id
}

#############################
# VPC Flow Logs -> CloudWatch
#############################
resource "aws_cloudwatch_log_group" "vpc_flow" {
  name              = "/aws/vpc/${var.name}-${var.env}-flowlogs"
  retention_in_days = 90

  tags = merge(var.tags, {
    Name = "${var.name}-${var.env}-vpc-flowlogs"
  })
}

resource "aws_iam_role" "flowlogs" {
  name = "${var.name}-${var.env}-vpc-flowlogs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "vpc-flow-logs.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "flowlogs" {
  name = "${var.name}-${var.env}-vpc-flowlogs-policy"
  role = aws_iam_role.flowlogs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_flow_log" "vpc" {
  vpc_id               = aws_vpc.this.id
  traffic_type         = "ALL"
  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.vpc_flow.arn
  iam_role_arn         = aws_iam_role.flowlogs.arn

  tags = merge(var.tags, {
    Name = "${var.name}-${var.env}-vpc-flowlogs"
  })
}
