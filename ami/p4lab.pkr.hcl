source "virtualbox-vm" "p4lab" {
  communicator = "ssh"
  ssh_username = "p4"
  ssh_password = "p4"
  shutdown_command = "shutdown -n"
  vm_name = "P4-tip"  
  format = "ova"
}

build {
  sources = ["source.virtualbox-vm.p4lab"]

  provisioner "shell" {
      inline = [
        "sudo chown -R p4: /home/p4/tutorials/exercises/blackholing"
      ]
  }

  # needs a vmimport role:
  # https://docs.aws.amazon.com/vm-import/latest/userguide/vmie_prereqs.html#vmimport-role
  post-processors {
    post-processor "amazon-import" { 
        region = "us-east-1"
        s3_bucket_name = "packerpost"
    }
  }
}


