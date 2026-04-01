# AMI (Amazon Machine Image): imagen base de Ubuntu 22.04 LTS publicada
# por Canonical (ID de cuenta: 099720109477). Se selecciona la más reciente.
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-22.04-amd64-server-*"]
  }
}

# Instancia pública que sirve el sitio estático con nginx y actúa como
# reverse proxy hacia el backend. Recibe tráfico HTTP desde internet.
resource "aws_instance" "frontend" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.publica.id
  associate_public_ip_address = true
  key_name                    = aws_key_pair.bootcamp.key_name
  vpc_security_group_ids      = [aws_security_group.taller_iac_bootcamperu_publico.id, aws_security_group.taller_iac_bootcamperu_comun.id]

  tags = {
    Name = "Instancia Frontend"
  }
}

# Instancia privada que ejecuta la aplicación Flask. Se ubica en la subnet
# privada sin IP pública: solo es alcanzable desde el frontend vía IP privada.
# El acceso SSH se realiza a través del frontend como bastion host.
resource "aws_instance" "backend" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.privada.id
  associate_public_ip_address = false
  key_name                    = aws_key_pair.bootcamp.key_name
  vpc_security_group_ids      = [aws_security_group.taller_iac_bootcamperu_privado.id, aws_security_group.taller_iac_bootcamperu_comun.id]

  tags = {
    Name = "Instancia Backend"
  }
}
