module "label_vpc" {
  source     = "cloudposse/label/null"
  version    = "0.25.0"
  context    = module.base_label.context
  name       = "vpc"
  attributes = ["main"]
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = module.label_vpc.tags
}

# =========================
# sub nets
# =========================
module "subnets" {
  source  = "hashicorp/subnets/cidr"
  version = "1.0.0"

  networks              = [aws_vpc.main.cidr_block]
  number_of_subnet_bits = 8
  newbits               = 0
  tags                  = module.label_vpc.tags
}

data "aws_availability_zones" "available" {}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = module.subnets.subnets[0].cidr_block
  availability_zone = random_element(data.aws_availability_zones.available.names)
  tags              = merge(module.label_vpc.tags, { Name = "public-subnet" })
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = module.subnets.subnets[1].cidr_block
  availability_zone = random_element(data.aws_availability_zones.available.names)
  tags              = merge(module.label_vpc.tags, { Name = "private-subnet" })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = module.label_vpc.tags
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags   = module.label_vpc.tags

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}
