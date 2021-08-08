variable "image_name" {
  default = "ssh-ingress"
}

# source blocks configure your builder plugins; your source is then used inside
# build blocks to create resources. A build block runs provisioners and
# post-processors on an instance created by the source.
source "amazon-ebs" "ssh-ingress" {
  ami_name      = var.image_name
  instance_type = "t2.micro"
  source_ami    = "ami-0fbec3e0504ee1970" # amzn2-ami-hvm-2.0.20210326.0-x86_64-gp2
  ssh_username = "ec2-user"
  tags = {
    created-date = "{{ isotime }}"
  }
}

# a build block invokes sources and runs provisioning steps on them.
build {
  sources = ["source.amazon-ebs.ssh-ingress"]

  provisioner "shell" {
    inline = [
      "sudo yum update -y",
      "sudo yum install iptables-services yum-cron -y",
      "sudo systemctl enable iptables",
      "sudo systemctl start iptables",
      "sudo systemctl enable yum-cron",
      "sudo systemctl start yum-cron"
    ]
  }
  provisioner "shell" {
    inline = [
      "sudo iptables -I INPUT -s 0.0.0.0/0 -d 0.0.0.0/0 -p tcp --dport 80 -m state --state New -j ACCEPT",
      "sudo iptables -I INPUT -s 0.0.0.0/0 -d 0.0.0.0/0 -p tcp --dport 443 -m state --state New -j ACCEPT",
      "sudo iptables -I INPUT -s 0.0.0.0/0 -d 0.0.0.0/0 -p tcp --dport 8080 -m state --state New -j ACCEPT",
      "sudo iptables -I INPUT -s 0.0.0.0/0 -d 0.0.0.0/0 -p tcp --dport 8443 -m state --state New -j ACCEPT",
      "sudo iptables -A PREROUTING -t nat -i eth0 -p tcp --dport 80 -j REDIRECT --to-port 8080",
      "sudo iptables -A PREROUTING -t nat -i eth0 -p tcp --dport 443 -j REDIRECT --to-port 8443",
      "sudo service iptables save"
    ]
  }
  provisioner "shell" {
    inline = [
      "echo 'GatewayPorts yes' | sudo tee -a /etc/ssh/sshd_config",
      "sudo systemctl restart sshd"
    ]
  }
}
