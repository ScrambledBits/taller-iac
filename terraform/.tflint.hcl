# TFLint: linter estático para Terraform. Detecta errores que 'terraform validate' no encuentra:
# tipos de instancia inválidos, regiones inexistentes, parámetros obsoletos, y malas prácticas
# específicas de cada proveedor. Funciona leyendo el código HCL sin conectarse a AWS.
#
# Ejecutar localmente:
#   tflint --config=.tflint.hcl --init   # descarga los plugins definidos aquí (solo la primera vez)
#   tflint --config=.tflint.hcl          # analiza todos los archivos .tf del directorio
#
# El pipeline de CI/CD (pipeline.yaml) lo ejecuta automáticamente en cada push y PR.

# Plugin AWS: añade reglas específicas de AWS al análisis.
# Sin este plugin, TFLint solo verifica sintaxis HCL genérica.
# Con él, detecta cosas como: tipo de instancia inexistente en la región, AMI ID con
# formato incorrecto, o parámetros deprecados del provider de AWS.
#
# version = "0.40.0": versión fijada para garantizar resultados reproducibles en todos
# los entornos (local, CI/CD). El plugin 0.40.x es la última versión compatible con TFLint 0.61.x.
# (0.41.x requiere TFLint 0.62+; no actualizar uno sin actualizar el otro.)
plugin "aws" {
  enabled = true
  version = "0.40.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

config {
  # call_module_type = "none": indica a TFLint que no intente analizar módulos externos.
  # Sin esta opción, TFLint intentaría descargar y analizar módulos referenciados con
  # 'source = "..."', lo que fallaría en el CI/CD si no hay acceso a internet o si el
  # módulo requiere autenticación. Este proyecto no usa módulos externos, así que la opción
  # es irrelevante aquí, pero es buena práctica declararla explícitamente para evitar
  # comportamientos inesperados si se añaden módulos en el futuro.
  call_module_type = "none"
}
