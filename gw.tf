resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.ecs-vpc.id
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.ecs-vpc.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gateway.id
}

resource "aws_eip" "gateway" {
  count      = 2
  domain     = "vpc"
  depends_on = [aws_internet_gateway.gateway]
}

resource "aws_nat_gateway" "gateway" {
  count         = 2
  subnet_id     = aws_subnet.public[count.index].id
  allocation_id = aws_eip.gateway[count.index].id

  tags = {
    Name = "nat-gateway-${count.index}"
  }
}

resource "aws_route_table" "private" {
  count  = 2
  vpc_id = aws_vpc.ecs-vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.gateway.*.id, count.index)
  }
}

resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
}