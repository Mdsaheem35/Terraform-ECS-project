resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "Munzir"
  }
}

resource "aws_subnet" "pubsub" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.0.0/17"

  tags = {
    Name = "pubsub"
  }
}

resource "aws_subnet" "privsub" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.192.0/24"

  tags = {
    Name = "privsub"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main"
  }
}



resource "aws_route_table" "pubrt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "pubrt"
  }
}

resource "aws_route_table" "privrt" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "privrt"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.privsub.id
  route_table_id = aws_route_table.privrt.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.pubsub.id
  route_table_id = aws_route_table.pubrt.id
}

resource "aws_ecr_repository" "mun" {
  name                 = "munzir"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}
resource "aws_ecs_cluster" "example" {
  name = "munzir"
}

resource "aws_ecs_cluster_capacity_providers" "example" {
  cluster_name = "munzir"

  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

           
resource "aws_ecs_task_definition" "service" {
  family = "test"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048

  container_definitions = jsonencode([
    {
      name      = "first"
      image     = "public.ecr.aws/l8b8m2k3/munzir:latest"
      cpu       = 1
      memory    = 512
      essential = true
      portMappings = [
        {
          name = "app"
	  containerPort = 80
          hostPort      = 80
	  
        }
      ]  
      runtimePlatform = [{
         "cpuArchitecture"="X86_64",
        "operatingSystemFamily"= "LINUX"
      }]
    }
])
}

