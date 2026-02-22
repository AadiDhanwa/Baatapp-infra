resource "aws_vpc" "chat_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "chat-vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.chat_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  availability_zone = "ap-south-1a"

  tags = {
    Name = "chat-public"
  }
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.chat_vpc.id
  cidr_block = "10.0.2.0/24"

  availability_zone = "ap-south-1a"

  tags = {
    Name = "chat-private"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.chat_vpc.id
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.chat_vpc.id
}

resource "aws_route" "internet" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}
resource "aws_security_group" "backend_sg" {
  name        = "chat-backend-sg"
  description = "Allow SSH HTTP HTTPS"
  vpc_id      = aws_vpc.chat_vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # WebSocket custom backend port (VERY IMPORTANT)
  ingress {
    description = "Backend API"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_key_pair" "chatkey" {
  key_name   = "chatkey"
  public_key = file("chatkey.pub")
}

#resource "aws_instance" "backend" {

# ami           = "ami-0f5ee92e2d63afc18"
# instance_type = "t2.micro"

# subnet_id = aws_subnet.public.id

# vpc_security_group_ids = [aws_security_group.backend_sg.id]

# key_name = aws_key_pair.chatkey.key_name

#associate_public_ip_address = true

#tags = {
# Name = "chat-backend-server"
#}
#}
resource "aws_security_group" "db_sg" {
  name   = "chat-db-sg"
  vpc_id = aws_vpc.chat_vpc.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.backend_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_db_subnet_group" "chat_db_subnet" {
  name = "chat-db-subnet"

  subnet_ids = [
    aws_subnet.private.id,
    aws_subnet.private2.id
  ]

  tags = {
    Name = "chat-db-subnet"
  }
}
resource "aws_db_instance" "chatdb" {

  identifier = "chat-db"

  engine            = "postgres"
  engine_version    = "15"
  instance_class    = "db.t3.micro"
  allocated_storage = 20

  username = "chatadmin"
  password = "StrongPassword123!"

  db_subnet_group_name   = aws_db_subnet_group.chat_db_subnet.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]

  publicly_accessible = false
  skip_final_snapshot = true
}
resource "aws_subnet" "private2" {
  vpc_id     = aws_vpc.chat_vpc.id
  cidr_block = "10.0.3.0/24"

  availability_zone = "ap-south-1b"

  tags = {
    Name = "chat-private-2"
  }
}
resource "aws_security_group" "redis_sg" {
  name   = "chat-redis-sg"
  vpc_id = aws_vpc.chat_vpc.id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.backend_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_elasticache_subnet_group" "chat_redis_subnet" {
  name = "chat-redis-subnet"

  subnet_ids = [
    aws_subnet.private.id,
    aws_subnet.private2.id
  ]
}
resource "aws_elasticache_cluster" "redis" {

  cluster_id      = "chat-redis"
  engine          = "redis"
  node_type       = "cache.t3.micro"
  num_cache_nodes = 1
  port            = 6379

  subnet_group_name  = aws_elasticache_subnet_group.chat_redis_subnet.name
  security_group_ids = [aws_security_group.redis_sg.id]
}
resource "aws_security_group" "alb_sg" {
  name   = "chat-alb-sg"
  vpc_id = aws_vpc.chat_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
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
}
resource "aws_lb" "chat_alb" {
  name               = "chat-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [aws_security_group.alb_sg.id]

  subnets = [
    aws_subnet.public.id,
    aws_subnet.public2.id
  ]
}

resource "aws_lb_target_group" "chat_tg" {

  name     = "chat-tg"
  port     = 8000
  protocol = "HTTP"
  vpc_id   = aws_vpc.chat_vpc.id

  health_check {
    path = "/"
    port = "8000"
  }
}

resource "aws_lb_listener" "chat_listener" {

  load_balancer_arn = aws_lb.chat_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.chat_tg.arn
  }
}
resource "aws_subnet" "public2" {
  vpc_id     = aws_vpc.chat_vpc.id
  cidr_block = "10.0.4.0/24"

  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "chat-public-2"
  }
}
resource "aws_route_table_association" "public2_assoc" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.public_rt.id
}
resource "aws_launch_template" "chat_lt" {

  name_prefix   = "chat-template"
  image_id      = "ami-03f4878755434977f"
  instance_type = "t2.micro"

  key_name = aws_key_pair.chatkey.key_name

  vpc_security_group_ids = [aws_security_group.backend_sg.id]

  user_data = base64encode(<<EOF
#!/bin/bash
apt update -y
apt install python3 -y
nohup python3 -m http.server 8000 &
EOF
  )
}
resource "aws_autoscaling_group" "chat_asg" {

  desired_capacity = 2
  max_size         = 3
  min_size         = 1

  vpc_zone_identifier = [
    aws_subnet.public.id,
    aws_subnet.public2.id
  ]

  launch_template {
    id      = aws_launch_template.chat_lt.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.chat_tg.arn]
}