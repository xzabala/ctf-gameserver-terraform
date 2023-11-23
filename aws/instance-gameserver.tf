resource "aws_instance" "gameserver" {
  ami                         = "ami-058bd2d568351da34"
  instance_type               = var.aws-instance-type

  key_name                    = aws_key_pair.gameserver-ssh-key.key_name

  network_interface {
    network_interface_id = aws_network_interface.gameserver-priv-interface.id
    device_index         = 0
  }

  root_block_device {
    volume_type           = "gp2"
    volume_size           = var.instance_root_block_device_volume_size
    delete_on_termination = true
  }

  tags = {
    Name        = "gameserver"
  }
}

resource "aws_eip" "gameserver-eip" {
  instance = aws_instance.gameserver.id
  vpc      = true
}

resource "null_resource" "gameserver-config2" {
  depends_on = [
    aws_instance.gameserver,
    aws_eip.gameserver-eip
  ]

  connection {
    type        = "ssh"
    host        = aws_eip.gameserver-eip.public_ip
    user        = var.gameserver-instance-username
    port        = "22"
    private_key = tls_private_key.gameserver-tls-key.private_key_openssh
    agent       = false
  }

  provisioner "file" {
    source      = "scripts/gameserver-config.sh"
    destination = "/home/${var.gameserver-instance-username}/gameserver-config.sh"
  }

  provisioner "file" {
    source      = "files/gameserver/ctf-gameserver_1.0_all.deb"
    destination = "/home/${var.gameserver-instance-username}/ctf-gameserver_1.0_all.deb"
  }

  provisioner "file" {
    source      = "files/gameserver/playbook.yml"
    destination = "/home/${var.gameserver-instance-username}/playbook.yml"
  }

  provisioner "file" {
    source      = "files/gameserver/uwsgi.ini"
    destination = "/home/${var.gameserver-instance-username}/uwsgi.ini"
  }

  provisioner "file" {
    source      = "files/gameserver/nginx.conf"
    destination = "/home/${var.gameserver-instance-username}/nginx.conf"
  }

  # provisioner "remote-exec" {
  #   inline = [
  #     "chmod +x /home/${var.gameserver-instance-username}/gameserver-config.sh",
  #     "sudo /home/${var.gameserver-instance-username}/gameserver-config.sh"
  #   ]
  # }
}
