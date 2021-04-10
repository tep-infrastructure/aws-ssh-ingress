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
    inline = [ "echo 'SSH Ingress'" ]
  }
}
