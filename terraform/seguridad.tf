# Estrategia de tres security groups:
#
#   publico  — acceso al frontend desde internet: HTTP :80.
#              Solo el frontend tiene este SG asignado.
#
#   privado  — acceso al backend: Flask :5000 exclusivamente desde instancias que tengan
#              el SG público asignado (referencia SG-a-SG). Es más preciso que un CIDR:
#              restringe el origen a una identidad concreta, no a un rango de IPs.
#
#   comun    — reglas compartidas por ambas instancias: SSH :22 y egress total.
#              Separarlo evita duplicar reglas y facilita revocar accesos de forma global.

# SG del frontend: expone el puerto 80 a internet.
resource "aws_security_group" "taller_iac_bootcamperu_publico" {
  name        = "${local.prefijo_proyecto}_publico"
  description = "SG del proyecto ${var.nombre_proyecto}"
  vpc_id      = aws_vpc.bootcamperu_taller.id

  tags = {
    Name = "taller_iac_bootcamperu_publico"
  }
}

resource "aws_vpc_security_group_ingress_rule" "permitir_http" {
  security_group_id = aws_security_group.taller_iac_bootcamperu_publico.id
  description       = "HTTP publico para el frontend"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

# SG del backend: solo recibe tráfico del frontend, nunca de internet directamente.
resource "aws_security_group" "taller_iac_bootcamperu_privado" {
  name        = "${local.prefijo_proyecto}_privado"
  description = "SG del proyecto ${var.nombre_proyecto}"
  vpc_id      = aws_vpc.bootcamperu_taller.id

  tags = {
    Name = "taller_iac_bootcamperu_privado"
  }
}

# Permite el puerto 5000 (Flask) únicamente desde instancias que tengan el SG público.
# Con referenced_security_group_id la regla se evalúa dinámicamente: si el frontend
# cambia de IP, la regla sigue siendo válida porque se basa en identidad, no en dirección.
resource "aws_vpc_security_group_ingress_rule" "permitir_proxy" {
  security_group_id            = aws_security_group.taller_iac_bootcamperu_privado.id
  referenced_security_group_id = aws_security_group.taller_iac_bootcamperu_publico.id
  description                  = "Flask :5000 solo desde el frontend (SG-a-SG)"
  from_port                    = 5000
  ip_protocol                  = "tcp"
  to_port                      = 5000
}

# SG común: aplicado a ambas instancias. Centraliza las reglas de SSH y de salida.
resource "aws_security_group" "taller_iac_bootcamperu_comun" {
  name        = "${local.prefijo_proyecto}_comun"
  description = "SG del proyecto ${var.nombre_proyecto}"
  vpc_id      = aws_vpc.bootcamperu_taller.id

  tags = {
    Name = "taller_iac_bootcamperu_comun"
  }
}

# Permite todo el tráfico de salida (egress). Las instancias necesitan acceso a internet
# para instalar paquetes con apt y pip. ip_protocol = "-1" significa "todos los protocolos".
resource "aws_vpc_security_group_egress_rule" "permitir_trafico_salida" {
  security_group_id = aws_security_group.taller_iac_bootcamperu_comun.id
  description       = "Egress total para apt/pip - restringir en produccion"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# Permite SSH desde cualquier IP. En producción se restringiría a IPs conocidas
# o se eliminaría en favor de AWS Systems Manager Session Manager.
resource "aws_vpc_security_group_ingress_rule" "permitir_ssh" {
  security_group_id = aws_security_group.taller_iac_bootcamperu_comun.id
  description       = "SSH abierto para el taller - restringir en produccion"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}


# Permite SSH al backend únicamente desde instancias que tengan el SG común (el frontend).
# Complementa la regla de SG común (SSH desde 0.0.0.0/0) con una restricción explícita SG-a-SG
# que hace visible la intención de acceso: solo el frontend puede abrir un túnel ProxyCommand al backend.
resource "aws_vpc_security_group_ingress_rule" "permitir_ssh_backend" {
  security_group_id            = aws_security_group.taller_iac_bootcamperu_privado.id
  referenced_security_group_id = aws_security_group.taller_iac_bootcamperu_comun.id
  from_port                    = 22
  ip_protocol                  = "tcp"
  to_port                      = 22
  description                  = "SSH al backend solo desde el frontend via ProxyCommand"
}

# Permite el scraping de métricas de node_exporter. Restringir var.monitoreo_cidr en producción.
resource "aws_vpc_security_group_ingress_rule" "permitir_node_exporter" {
  security_group_id = aws_security_group.taller_iac_bootcamperu_comun.id
  description       = "node_exporter metrics - restringir en produccion"
  cidr_ipv4         = var.monitoreo_cidr
  from_port         = 9100
  ip_protocol       = "tcp"
  to_port           = 9100
}

# Permite el acceso a Grafana. Restringir var.monitoreo_cidr en producción.
resource "aws_vpc_security_group_ingress_rule" "permitir_grafana" {
  security_group_id = aws_security_group.taller_iac_bootcamperu_comun.id
  description       = "Grafana dashboard - restringir en produccion"
  cidr_ipv4         = var.monitoreo_cidr
  from_port         = 3000
  ip_protocol       = "tcp"
  to_port           = 3000
}
