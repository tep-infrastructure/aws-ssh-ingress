# If you don't set a default, then you will need to provide the variable
# at run time using the command line, or set it in the environment. For more
# information about the various options for setting variables, see the template
# [reference documentation](https://www.packer.io/docs/templates)
variable "ami_name" {
  type    = string
  default = "ssh-ingress"
}

locals { timestamp = regex_replace(timestamp(), "[- TZ:]", "") }

# source blocks configure your builder plugins; your source is then used inside
# build blocks to create resources. A build block runs provisioners and
# post-processors on an instance created by the source.
source "amazon-ebs" "ssh-ingress" {
  ami_name      = "ssh-ingress ${local.timestamp}"
  instance_type = "t2.micro"
  source_ami    = "ami-0fbec3e0504ee1970" # amzn2-ami-hvm-2.0.20210326.0-x86_64-gp2
  ssh_username = "ec2-user"
}

# a build block invokes sources and runs provisioning steps on them.
build {
  sources = ["source.amazon-ebs.ssh-ingress"]

  provisioner "shell" {
    inline = [ "sudo yum update -y" ]
  }
  provisioner "shell" {
    inline = [
      "sudo iptables -I INPUT -s 0.0.0.0/0 -d 0.0.0.0/0 -p tcp --dport 80 -m state --state New -j ACCEPT",
      "sudo iptables -I INPUT -s 0.0.0.0/0 -d 0.0.0.0/0 -p tcp --dport 443 -m state --state New -j ACCEPT",
      "sudo iptables -I INPUT -s 0.0.0.0/0 -d 0.0.0.0/0 -p tcp --dport 8080 -m state --state New -j ACCEPT",
      "sudo iptables -I INPUT -s 0.0.0.0/0 -d 0.0.0.0/0 -p tcp --dport 8443 -m state --state New -j ACCEPT",
      "sudo iptables -A PREROUTING -t nat -i eth0 -p tcp --dport 80 -j REDIRECT --to-port 8080",
      "sudo iptables -A PREROUTING -t nat -i eth0 -p tcp --dport 443 -j REDIRECT --to-port 8443",
      "sudo /sbin/service iptables save"
    ]
  }
  provisioner "shell" {
    inline = [ "echo 'SSH Ingress'" ]
  }
}
