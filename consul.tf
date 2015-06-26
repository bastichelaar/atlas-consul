#--------------------------------------------------------------
# Instance
#--------------------------------------------------------------
provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
}

resource "aws_instance" "server" {

    subnet_id = "${aws_subnet.main.id}"
    security_groups = ["${aws_security_group.allow_all.id}"]

    ami = "${lookup(var.ami, concat(var.region, "-", var.platform))}"
    instance_type = "${var.instance_type}"
    key_name = "${aws_key_pair.consul.key_name}"
    count = "${var.servers}"
    security_groups = ["${aws_security_group.allow_all.id}"]

    connection {
        user = "${lookup(var.user, var.platform)}"
        key_file = "${var.private_key}"
    }

    #Instance tags
    tags {
        Name = "${var.tagName}-${count.index}"
    }

    provisioner "file" {
        source = "${path.module}/scripts/${var.platform}/upstart.conf"
        destination = "/tmp/upstart.conf"
    }

    provisioner "file" {
        source = "${path.module}/scripts/${var.platform}/upstart-join.conf"
        destination = "/tmp/upstart-join.conf"
    }

    provisioner "remote-exec" {
        inline = [
            "echo ${var.servers} > /tmp/consul-server-count",
            "echo ${aws_instance.server.0.private_dns} > /tmp/consul-server-addr",
        ]
    }

    provisioner "remote-exec" {
        scripts = [
            "${path.module}/scripts/${var.platform}/install.sh",
            "${path.module}/scripts/${var.platform}/server.sh",
            "${path.module}/scripts/${var.platform}/service.sh",
        ]
    }
}


#--------------------------------------------------------------
# Security Group
#--------------------------------------------------------------
resource "aws_security_group" "allow_all" {
  name = "allow_all"
  description = "Allow all inbound traffic"

  ingress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }
}

#--------------------------------------------------------------
# VPC
#--------------------------------------------------------------
#resource "aws_vpc" "main" {
#    cidr_block = "172.31.0.0/16"
#    enable_dns_hostnames = true
#}
#
#resource "aws_subnet" "main" {
#    vpc_id = "${aws_vpc.main.id}"
#    cidr_block = "172.31.0.0/20"
#    map_public_ip_on_launch = true
#}
#
#resource "aws_internet_gateway" "gw" {
#    vpc_id = "${aws_vpc.main.id}"
#}
#
#resource "aws_route_table" "r" {
#    vpc_id = "${aws_vpc.main.id}"
#    route {
#        cidr_block = "0.0.0.0/0"
#        gateway_id = "${aws_internet_gateway.gw.id}"
#    }
#}
#
#resource "aws_main_route_table_association" "a" {
#    vpc_id = "${aws_vpc.main.id}"
#    route_table_id = "${aws_route_table.r.id}"
#}

resource "aws_key_pair" "consul" {
    key_name = "consul-key-pair"
    public_key = "${file(var.public_key)}"
}
