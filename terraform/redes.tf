# Red virtual privada que aísla todos los recursos del proyecto.
# El bloque CIDR 10.0.0.0/16 reserva 65 536 direcciones IP privadas.
resource "aws_vpc" "bootcamperu_taller" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "VPC principal"
  }
}

# Subnet pública: las instancias aquí pueden tener IP pública y recibir
# tráfico de internet a través del Internet Gateway.
resource "aws_subnet" "publica" {
  vpc_id            = aws_vpc.bootcamperu_taller.id
  cidr_block        = var.public_subnet_cidr
  availability_zone = var.availability_zone

  tags = {
    Name = "Subnet Publica"
  }
}

# Subnet privada: las instancias aquí NO tienen IP pública y no son alcanzables
# directamente desde internet. El backend vive aquí por seguridad.
resource "aws_subnet" "privada" {
  vpc_id            = aws_vpc.bootcamperu_taller.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = var.availability_zone

  tags = {
    Name = "Subnet Privada"
  }
}

# Puerta de entrada/salida entre la VPC e internet. Sin IGW, ninguna instancia
# puede enviar ni recibir tráfico de internet, aunque tenga IP pública asignada.
resource "aws_internet_gateway" "igw_principal" {
  vpc_id = aws_vpc.bootcamperu_taller.id

  tags = {
    Name = "IGW Principal"
  }
}

# Route table de la subnet pública: envía todo el tráfico externo (0.0.0.0/0) al IGW.
# Sin esta ruta, las instancias con IP pública tampoco podrían comunicarse con internet.
resource "aws_route_table" "publica" {
  vpc_id = aws_vpc.bootcamperu_taller.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_principal.id
  }
}

# Asocia la route table pública con la subnet pública.
# Una subnet sin asociación explícita usa la route table principal de la VPC,
# que por defecto no tiene ruta a internet.
resource "aws_route_table_association" "publico" {
  subnet_id      = aws_subnet.publica.id
  route_table_id = aws_route_table.publica.id
}

# IP elástica (estática) para el NAT gateway. Debe estar en el dominio "vpc"
# para ser usada con recursos dentro de una VPC.
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "EIP NAT Gateway"
  }
}

# NAT gateway en la subnet pública: permite que las instancias privadas accedan
# a internet para instalar paquetes (apt, pip), sin exponer una IP pública propia.
# El tráfico sale por el NAT (que sí tiene IP pública), pero las conexiones entrantes
# desde internet no pueden iniciarse hacia las instancias privadas.
# Depende del IGW porque el NAT necesita esa ruta de salida para funcionar.
resource "aws_nat_gateway" "principal" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.publica.id

  tags = {
    Name = "NAT Gateway Principal"
  }

  depends_on = [aws_internet_gateway.igw_principal]
}

# Route table de la subnet privada: envía el tráfico externo al NAT gateway,
# no al IGW. El NAT traduce la IP privada de origen a su propia IP pública
# antes de enviar el paquete a internet (eso es NAT: Network Address Translation).
resource "aws_route_table" "privada" {
  vpc_id = aws_vpc.bootcamperu_taller.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.principal.id
  }

  tags = {
    Name = "Route Table Privada"
  }
}

# Asocia la route table privada con la subnet privada.
resource "aws_route_table_association" "privado" {
  subnet_id      = aws_subnet.privada.id
  route_table_id = aws_route_table.privada.id
}
