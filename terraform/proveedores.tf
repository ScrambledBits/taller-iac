# Define los providers que Terraform necesita y configura el backend de estado remoto en S3.
# Este archivo es el punto de partida de cualquier módulo de Terraform: sin él, Terraform
# no sabe con qué API hablar ni dónde guardar el registro de la infraestructura creada.
#
# Ejecutar 'terraform init' después de cualquier cambio aquí para que Terraform descargue
# o actualice los providers y reconecte con el backend S3.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.37.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  # Estado remoto en S3: el .tfstate vive en S3 en lugar de en disco local.
  # Esto permite que varios miembros del equipo (o el CI/CD) compartan y lean el mismo estado.
  # use_lockfile = true crea un lock en S3 durante el apply para evitar ejecuciones simultáneas.
  # encrypt = true cifra el archivo de estado en reposo (el bucket también debe tener SSE habilitado).
  #
  # NOTA: Los bloques backend se evalúan antes de que Terraform resuelva las variables,
  # por lo que no pueden usar var.*. Si necesitas parametrizar el bucket o la key,
  # usa: terraform init -backend-config="bucket=mi-bucket"
  backend "s3" {
    bucket       = "bootcamperu-tf-state"
    key          = "bootcamperu.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }
}

provider "aws" {
  region = var.region

  # default_tags aplica estas etiquetas a todos los recursos del provider de forma automática,
  # sin necesidad de repetirlas en cada bloque tags = {}. Es la práctica recomendada para
  # mantener un etiquetado consistente y facilitar la búsqueda y el control de costos en AWS.
  default_tags {
    tags = {
      Environment = "dev"
      Owner       = "Emilio Castro"
      Project     = "taller-bootcamperu"
      ManagedBy   = "terraform"
      Team        = "DevOps"
    }
  }
}
