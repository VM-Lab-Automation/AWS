locals { timestamp = regex_replace(timestamp(), "[- TZ:]", "") }

# source blocks configure your builder plugins; your source is then used inside
# build blocks to create resources. A build block runs provisioners and
# post-processors on an instance created by the source.
source "amazon-ebs" "amzn_ecs_worker" {
  ami_name      = "amzn_ecs_worker ${local.timestamp}"
  instance_type = "t2.micro"
  region        = "us-east-1"
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/*/ubuntu-focal-20.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }
  ssh_username = "ubuntu"
}

variable "ecs_config" {
  type = string
  default = <<EOF
    ECS_DATADIR=/data
    ECS_ENABLE_TASK_IAM_ROLE=true
    ECS_ENABLE_TASK_IAM_ROLE_NETWORK_HOST=true
    ECS_LOGFILE=/log/ecs-agent.log
    ECS_AVAILABLE_LOGGING_DRIVERS=["json-file","awslogs"]
    ECS_LOGLEVEL=info
  EOF
}

# a build block invokes sources and runs provisioning steps on them.
build {
  sources = ["source.amazon-ebs.amzn_ecs_worker"]

  provisioner "shell" {
      inline = [
        "sleep 20",
        "sudo apt-get update",
        "curl -fsSL https://get.docker.com | sudo sh",
        "sudo bash -c \"echo 'net.ipv4.conf.all.route_localnet = 1' >> /etc/sysctl.conf\"",
        "sudo sysctl -p /etc/sysctl.conf",
        "echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections",
        "echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections",
        "sudo apt-get install -y iptables-persistent",
        "sudo iptables -t nat -A PREROUTING -p tcp -d 169.254.170.2 --dport 80 -j DNAT --to-destination 127.0.0.1:51679",
        "sudo iptables -t nat -A OUTPUT -d 169.254.170.2 -p tcp -m tcp --dport 80 -j REDIRECT --to-ports 51679",
        "sudo iptables -A INPUT -i eth0 -p tcp --dport 51678 -j DROP",
        "sudo sh -c 'iptables-save > /etc/iptables/rules.v4'",
        "sudo mkdir -p /etc/ecs && sudo touch /etc/ecs/ecs.config",
        "echo -n ${var.ecs_config}",
        "sudo sh -c 'echo ${var.ecs_config} >> /etc/ecs/ecs.config'",
        "sudo cat /etc/ecs/ecs.config",
        "curl -o ecs-agent.tar https://s3.amazonaws.com/amazon-ecs-agent-us-east-1/ecs-agent-latest.tar",
        "sudo docker load --input ./ecs-agent.tar",
        "sudo docker run --name ecs-agent --detach=true --restart=on-failure:10 --volume=/var/run:/var/run --volume=/var/log/ecs/:/log --volume=/var/lib/ecs/data:/data --volume=/etc/ecs:/etc/ecs --net=host --env-file=/etc/ecs/ecs.config amazon/amazon-ecs-agent:latest",
        "sudo apt-get -y install virtualbox"
      ]
    }

}


