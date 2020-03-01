provider "aws" {
  access_key = "AKIAWQXH7YAS57ITXNHZ"
  secret_key = "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"
  region     = "ap-south-1"
}

resource "aws_vpc" "first_terrafor" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "first_terraform"
  }
}
resource "aws_subnet" "sub_1" {
  vpc_id     = "${aws_vpc.first_terrafor.id}"
  cidr_block = "10.0.0.0/24"
  availability_zone = "ap-south-1a"
  tags = {
    Name = "sub_1"
  }
}
resource "aws_internet_gateway" "gw1" {
  vpc_id = "${aws_vpc.first_terrafor.id}"

  tags = {
    Name = "IG_1"
  }
}
resource "aws_route_table" "vpc1_rt" {
  vpc_id = "${aws_vpc.first_terrafor.id}"
  route  {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw1.id}"
  }
  tags = {
    Name = "rt_1"
  }
}

resource "aws_route_table_association" "subass_1" {
  route_table_id = "${aws_route_table.vpc1_rt.id}"
  subnet_id      = "${aws_subnet.sub_1.id}"
}


resource "aws_security_group" "sg_1" {
  vpc_id = "${aws_vpc.first_terrafor.id}"
  name   = "sg_1"
  ingress {
    
    from_port     = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    
    from_port     = 80
    to_port     = 80
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


resource "aws_instance" "webu" {
  ami                         = "ami-0620d12a9cf777c87"
  subnet_id                   = "${aws_subnet.sub_1.id}"
  instance_type               = "t2.micro"
  key_name                    = "ansible"
  associate_public_ip_address = "true"
  vpc_security_group_ids      = ["${aws_security_group.sg_1.id}"]

tags = {
    Name = "TerrafromApache"
  }
 connection {
    type        = "ssh"
    user        = "ubuntu"
    host = "${aws_instance.webu.public_ip}"
    private_key = "${file("./ansible.pem")}"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo apt update -y",
      "sudo apt install software-properties-common -y",
      "sudo apt-add-repository --yes --update ppa:ansible/ansible",
      "sudo apt install ansible -y",
      "sudo git clone https://github.com/adamalli01/apache.git",
      "ansible-playbook  /home/ubuntu/apache/playbook.yml"
    ]
  }
}

module "alarm" {
      source                    = "git::https://github.com/clouddrove/terraform-aws-cloudwatch-alarms.git"
      name                      = "alarm"
      application               = "clouddrove"
      environment               = "test"
      label_order               = ["environment", "name", "application"]
      alarm_name                = "cpu-alarm"
      comparison_operator       = "LessThanThreshold"
      evaluation_periods        = 2
      metric_name               = "CPUUtilization"
      namespace                 = "AWS/EC2"
      period                    = "60"
      statistic                 = "Average"
      threshold                 = "40"
      alarm_description         = "This metric monitors ec2 cpu utilization"
      alarm_actions             = ["arn:aws:sns:ap-south-1:448236863525:test"]
      actions_enabled           = true
      insufficient_data_actions = []
      ok_actions                = []
      instance_id               = "${aws_instance.webu.id}"

  }
