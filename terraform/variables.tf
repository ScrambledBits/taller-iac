# Parámetros configurables del módulo. Cada variable tiene un valor predeterminado
# que funciona para el taller, pero puede sobreescribirse en terraform.tfvars o con
# la opción -var= en la línea de comandos.
#
# Ejemplo: terraform apply -var="instance_type=t3.medium"

variable "region" {
  type        = string
  description = "Región de AWS donde se desplegarán los recursos"
  default     = "us-east-1"
}

# 10.0.0.0/16 pertenece al espacio RFC 1918 (IPs privadas, no enrutables en internet).
# El prefijo /16 reserva 65 536 direcciones — mucho más de lo necesario para dos subnets,
# pero deja margen para añadir más subnets en el futuro sin rediseñar la red.
# Las dos subnets (/24, 256 direcciones cada una) están bien contenidas dentro de este bloque.
variable "vpc_cidr" {
  type        = string
  description = "Bloque CIDR de la VPC"
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  type        = string
  description = "Bloque CIDR de la subnet pública"
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  type        = string
  description = "Bloque CIDR de la subnet privada"
  default     = "10.0.2.0/24"
}

# t3.small (2 vCPU con créditos de CPU, 2 GB de RAM) es el mínimo cómodo para este taller:
# t3.micro (1 GB) puede quedarse sin memoria si apt upgrade y Flask corren al mismo tiempo.
# t3.medium es innecesario para este volumen de tráfico y dobla el costo de t3.small.
# La validación limita las opciones a estos tres tamaños para evitar despliegues accidentales
# de instancias más grandes (y más caras) por un error tipográfico en terraform.tfvars.
variable "instance_type" {
  type        = string
  description = "Tipo de instancia EC2 para todas las instancias"
  default     = "t3.small"
  validation {
    condition     = contains(["t3.micro", "t3.small", "t3.medium"], var.instance_type)
    error_message = "El tipo de instancia debe ser t3.micro, t3.small o t3.medium."
  }
}

variable "nombre_proyecto" {
  type        = string
  description = "Nombre del proyecto para identificar recursos en AWS"
  default     = "taller-bootcamperu"
}

variable "nombre_llave_ssh" {
  type        = string
  description = "Nombre del archivo de la llave SSH generada"
  default     = "taller.pem"
}

variable "usuario_ssh" {
  type        = string
  description = "Usuario del sistema operativo para conexiones SSH"
  default     = "ubuntu"
}

variable "monitoreo_cidr" {
  type        = string
  description = "CIDR desde el que se permite acceso a puertos de monitoreo (node_exporter :9100, Grafana :3000). Restringir a tu IP en producción."
  default     = "0.0.0.0/0"
}

# En este taller usamos una sola zona de disponibilidad para simplificar la arquitectura.
# En producción se usarían al menos dos AZs distintas (ej: us-east-1a y us-east-1b) para
# que la aplicación siga disponible si AWS tiene un problema en una zona física.
# Cambiar este valor si us-east-1a está saturada o para experimentar con otras zonas.
variable "availability_zone" {
  type        = string
  description = "Zona de disponibilidad donde se crean las subnets y las instancias EC2."
  default     = "us-east-1a"
}
