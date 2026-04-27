# Consulta dinámica de la AMI de Ubuntu 22.04 LTS más reciente publicada por Canonical.
# Usar 'data' en lugar de un AMI ID fijo garantiza que se usa la imagen más actualizada
# en cada región, sin necesidad de actualizar el código cuando Canonical publica parches.
#
# most_recent = true  → si hay varias imágenes que coinciden, usa la más nueva
# owners              → ID de cuenta de Canonical; evita usar AMIs de terceros no verificados
# filter name         → hvm-ssd: virtualización HVM (el tipo estándar y recomendado hoy)
#                       con almacenamiento EBS de tipo SSD
#
# Ubuntu 22.04 LTS (Jammy Jellyfish): versión con soporte extendido hasta abril 2027.
# Se eligió sobre versiones más recientes (24.04) por mayor compatibilidad con paquetes
# del sistema en el momento del taller, y sobre versiones más antiguas por recibir
# actualizaciones de seguridad activas.
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

  # metadata_options: configura el servicio de metadatos de la instancia (IMDS).
  # Las instancias EC2 pueden consultar sus propios metadatos (IP, región, credenciales IAM)
  # desde la dirección especial http://169.254.169.254, solo accesible desde dentro de la instancia.
  #
  # http_endpoint = "enabled": mantiene activo el endpoint de metadatos, necesario para
  #   herramientas del sistema operativo que consultan la región o la IP de la instancia.
  # http_tokens = "required": activa IMDSv2 (Instance Metadata Service versión 2), que exige
  #   que cada solicitud al endpoint incluya un token de sesión generado previamente.
  #
  # ¿Por qué importa IMDSv2? Protege contra ataques SSRF (Server-Side Request Forgery):
  # con IMDSv1, si una aplicación vulnerable reenvía solicitudes HTTP arbitrarias, un atacante
  # remoto podría obtener las credenciales IAM de la instancia accediendo al endpoint de metadatos.
  # IMDSv2 rompe ese ataque porque el token de sesión requiere una solicitud PUT previa que
  # los proxies SSRF no pueden realizar de forma transparente.
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

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

  # Misma configuración de IMDSv2 que el frontend. Ver comentario anterior para el detalle.
  # El backend también puede tener credenciales IAM si se le asigna un rol (no es el caso
  # en este taller), por lo que la protección sigue siendo relevante.
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = {
    Name = "Instancia Backend"
  }
}
