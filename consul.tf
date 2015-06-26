#--------------------------------------------------------------
# Instance
#--------------------------------------------------------------
provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
}

resource "aws_instance" "server" {

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
      to_port = 65535
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_key_pair" "consul" {
#    key_name = "consul-key-pair"
#    public_key = ""
}

resource "aws_key_pair" "consul" {
    key_name = "consul-key-pair"
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQC5LNW47his4cUNaXj1Ma634p+uIN27yb+aWR7UN4DQ1PullYtt9VOF2Vsi5kHsKkEdgGgUMPtCGkqnweJLwn/TKnGtDUWLWP/uWZ/r6R9ccRuT7RXodXAjZl8bVOPlBQk278YivDLMdwuEv7keVeHUvUKOkKIqNX7hh/xe4bKicQ=="
}
