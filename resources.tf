resource "aws_vpc" "vpc_environment" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_subnet" "public_subnet1" {
  cidr_block              = cidrsubnet(aws_vpc.vpc_environment.cidr_block, 4, 1)
  vpc_id                  = aws_vpc.vpc_environment.id
  availability_zone       = "us-west-2c"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private_subnet1" {
  cidr_block        = cidrsubnet(aws_vpc.vpc_environment.cidr_block, 4, 2)
  vpc_id            = aws_vpc.vpc_environment.id
  availability_zone = "us-west-2c"
}

resource "aws_subnet" "public_subnet2" {
  cidr_block              = cidrsubnet(aws_vpc.vpc_environment.cidr_block, 4, 3)
  vpc_id                  = aws_vpc.vpc_environment.id
  availability_zone       = "us-west-2b"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private_subnet2" {
  cidr_block        = cidrsubnet(aws_vpc.vpc_environment.cidr_block, 4, 4)
  vpc_id            = aws_vpc.vpc_environment.id
  availability_zone = "us-west-2b"
}

resource "aws_security_group" "private_subnesecurity" {
  vpc_id = aws_vpc.vpc_environment.id
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
  }
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
  }
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = -1
    protocol    = "icmp"
    to_port     = -1
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "security" {
  vpc_id = aws_vpc.vpc_environment.id

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
  }
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 443
    protocol    = "tcp"
    to_port     = 443
  }

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = -1
    protocol    = "icmp"
    to_port     = -1
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

variable "ami_key_pair_name" {
  default = "MyKP"
}

//internet gateway
resource "aws_internet_gateway" "default_gat" {
  vpc_id = aws_vpc.vpc_environment.id
}

//routing table for public subnets
resource "aws_route_table" "route-public" {
  vpc_id = aws_vpc.vpc_environment.id
//depends_on = [aws_vpc.vpc_environment]
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.default_gat.id
  }

  tags = {
    Name = "vpc Routing Table"
  }
}

//routing table for private subnet 1
resource "aws_route_table" "route-private1" {
  vpc_id = aws_vpc.vpc_environment.id
//  depends_on = [aws_subnet.private_subnet1]
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_1gate.id
  }

  tags = {
    Name = "Private Subnet 1 Routing Table"
  }
}

//routing table for private subnet 2
resource "aws_route_table" "route-private2" {
  vpc_id = aws_vpc.vpc_environment.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_1gate.id
  }

  tags = {
    Name = "Private Subnet 2 Routing Table"
  }
}

resource "aws_main_route_table_association" "main_table_assoc" {
  vpc_id         = aws_vpc.vpc_environment.id
  route_table_id = aws_route_table.route-public.id
}

resource "aws_route_table_association" "subnet1_table_assoc" {
  subnet_id      = aws_subnet.private_subnet1.id
  route_table_id = aws_route_table.route-private1.id
}
resource "aws_route_table_association" "subnet2_table_assoc" {
  subnet_id      = aws_subnet.private_subnet2.id
  route_table_id = aws_route_table.route-private2.id
}
variable "ami" {

  default = "ami-07669fc90e6e6cc47"
}
resource "aws_launch_configuration" "autoscale_launch_config" {
  name_prefix          = "autoscale_launcher-Craig-"
  image_id        = var.ami
  instance_type   = "t2.nano"
//  key_name        = var.ami_key_pair_name
  security_groups = [aws_security_group.security.id]
  enable_monitoring = true
  user_data = file(
    "C:/Users/Default.Default-PC/Downloads/install_apache_server2.sh"
  )
  lifecycle {create_before_destroy = true}
}


variable "min_asg" {
  default = 2
}

variable "des_asg" {
  default = 3
}

variable "max_asg" {
  default = 5
}


variable "min_asg2" {
  default = 0
}

variable "des_asg2" {
  default = 0
}

variable "max_asg2" {
  default = 0
}

resource "aws_autoscaling_group" "autoscale_group_1" {
  name="asg-${aws_launch_configuration.autoscale_launch_config.name}"
  launch_configuration = aws_launch_configuration.autoscale_launch_config.id
  vpc_zone_identifier  = [aws_subnet.private_subnet2.id, aws_subnet.private_subnet1.id]

  min_size = var.min_asg
  max_size = var.max_asg
  desired_capacity = var.des_asg
  wait_for_elb_capacity = 3

  tag {
    key                 = "Name"
    value               = "auto_scale-Craig"
    propagate_at_launch = true
  }

  health_check_grace_period = 200
  health_check_type = "ELB"
  //load_balancers = [aws_alb.alb.name]
  lifecycle {create_before_destroy = true}
  enabled_metrics = [

    "GroupInServiceInstances",
    "GroupTotalInstances"

  ]
  //depends_on = [data.aws_autoscaling_group.autoscale_group_1]
  metrics_granularity="1Minute"
/*provisioner "local-exec" {
  command = "check_health.sh ${aws_alb.alb.dns_name}"
}*/
}

resource "null_resource" "writeASGtoFile" {
  triggers = {
    the_trigger= join(",",[aws_autoscaling_group.autoscale_group_1.id, "0"])
  }
  depends_on = [aws_autoscaling_attachment.alb_autoscale]
  lifecycle {create_before_destroy = true}
  /*provisioner "local-exec" {
    command = "echo ${data.aws_autoscaling_group.autoscale_group_1.name}>ASGName.txt"
  }*/

}

data "aws_autoscaling_group" "autoscale_group_1" {
  name = aws_autoscaling_group.autoscale_group_1.name

}
output "autoscalingname" {
  value = [data.aws_autoscaling_group.autoscale_group_1.name, aws_alb_target_group.alb_target_group_1.arn]

}



/*
resource "aws_autoscaling_policy" "web_policy_up" {
  name = "web_policy_up"
  scaling_adjustment = 1
  adjustment_type = "ChangeInCapacity"
  cooldown = 300
  autoscaling_group_name = "${aws_autoscaling_group.autoscale_group_1.name}"
//  autoscaling_group_name = "${aws_autoscaling_group.web.name}"
  lifecycle {create_before_destroy = true}
}
resource "aws_cloudwatch_metric_alarm" "web_cpu_alarm_up" {
  alarm_name = "web_cpu_alarm_up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "2"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "120"
  statistic = "Average"
  threshold = "60"
  lifecycle {create_before_destroy = true}
  dimensions = {
    AutoScalingGroupName = "${aws_autoscaling_group.autoscale_group_1.name}"
//    "${aws_autoscaling_group.web.name}"
  }

  alarm_description = "This metric monitor EC2 instance CPU utilization"
 // alarm_actions = ["${aws_autoscaling_policy.web_policy_up.arn}"]
}
*/
resource "aws_alb_target_group" "alb_target_group_1" {
  name_prefix    = "targp-"
  port     = "80"
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc_environment.id


  tags = {
    name = "alb_target_group2"
  }
  stickiness {
    type            = "lb_cookie"
    cookie_duration = 1800
    enabled         = true
  }
  slow_start = 0
  deregistration_delay = 30
  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 2
    interval            = 15
    path                = "/"
    port                = 80
  }
  lifecycle {create_before_destroy = true}

}

resource "aws_autoscaling_attachment" "alb_autoscale" {
  alb_target_group_arn   = aws_alb_target_group.alb_target_group_1.arn
  autoscaling_group_name = aws_autoscaling_group.autoscale_group_1.id
  lifecycle {create_before_destroy = true}
  /*provisioner "local-exec" {
    command = "attchmnt_checkhealth.sh ${chomp(file("C:/Users/Default.Default-PC/Dropbox/Pason/Terraform/ASGName.txt"))} ${aws_alb_target_group.alb_target_group_1.arn}"
  }*/
//${file("C:/Users/Default.Default-PC/Dropbox/Pason/Terraform/ASGName.txt")}
}

resource "aws_alb" "alb" {
  name_prefix = "lbCrg-"
  subnets = [
    aws_subnet.public_subnet1.id,
    aws_subnet.public_subnet2.id]
  security_groups = [
    aws_security_group.security.id]
  internal = false

  idle_timeout = 2
  tags = {
    Name = "alb2"
  }
  lifecycle {create_before_destroy = true}
}

resource "aws_alb_listener" "alb_listener" {
  load_balancer_arn = aws_alb.alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    target_group_arn = aws_alb_target_group.alb_target_group_1.arn
    type             = "forward"
  }
  lifecycle {create_before_destroy = true}
}




resource "aws_nat_gateway" "nat_2gate" {
  allocation_id = aws_eip.nat_eip2.id
  subnet_id     = aws_subnet.public_subnet2.id
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_nat_gateway" "nat_1gate" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet1.id
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_eip" "nat_eip2" {

  vpc      = true
  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_eip" "nat_eip" {

  vpc      = true
  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_route_table" "routtable1" {

  vpc_id = aws_vpc.vpc_environment.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_1gate.id
  }


  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_route_table" "routtable2" {

  vpc_id = aws_vpc.vpc_environment.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_2gate.id
  }


  lifecycle {
    create_before_destroy = true
  }
}
/*
resource "aws_cloudwatch_log_metric_filter" "viewer_view_doc_bytes_read" {
  name           = "viewer_view_document_count"
  pattern        = ""
  log_group_name = aws_cloudwatch_log_group.log1.name
  metric_transformation {
    name         = "viewer_view_doc_bytes_read"
    namespace    = "LogMetrics"
    value        = 1
  }
}
resource "aws_cloudwatch_log_group" "log1" {
  name = "Log1"
}*/


/*
resource "aws_cloudformation_stack" "network" {
  name = "networking-stack"

  parameters = {
    VPCCidr = "10.0.0.0/16"
  }

  template_body = <<STACK
{
  "Parameters" : {
    "VPCCidr" : {
      "Type" : "String",
      "Default" : "10.0.0.0/16",
      "Description" : "Enter the CIDR block for the VPC. Default is 10.0.0.0/16."
    }
  },
  "Resources" : {
    "myVpc": {
      "Type" : "AWS::EC2::VPC",
      "Properties" : {
        "CidrBlock" : { "Ref" : "VPCCidr" },
        "Tags" : [
          {"Key": "Name", "Value": "Primary_CF_VPC"}
        ]
      }
    }
  }
}
STACK
}



*/