# Valores exportados tras el apply. Accesibles con:
#   terraform output              — muestra todos los outputs
#   terraform output <nombre>     — muestra un valor concreto
#   terraform output -raw <nombre>| bash  — ejecuta el valor directamente como comando

output "frontend_public_ip" {
  description = "Dirección IP pública del servidor frontend"
  value       = aws_instance.frontend.public_ip
}

output "backend_private_ip" {
  description = "Dirección IP privada del servidor backend (no tiene IP pública)"
  value       = aws_instance.backend.private_ip
}

output "vpc_id" {
  description = "ID de la VPC principal"
  value       = aws_vpc.bootcamperu_taller.id
}

output "public_subnet_id" {
  description = "ID de la subnet pública"
  value       = aws_subnet.publica.id
}

output "private_subnet_id" {
  description = "ID de la subnet privada donde reside el backend"
  value       = aws_subnet.privada.id
}

output "frontend_ssh_command" {
  description = "Comando SSH para conectarse al frontend directamente"
  value       = "ssh -i ${path.module}/${var.nombre_llave_ssh} ${var.usuario_ssh}@${aws_instance.frontend.public_ip}"
}

# El backend no tiene IP pública. Para SSH interactivo (uso humano) se usa ProxyJump:
# OpenSSH abre un túnel a través del frontend de forma transparente.
# Nota: Ansible usa ProxyCommand en el inventario generado — no ProxyJump —
# porque Ansible necesita pasar la llave SSH explícitamente al salto,
# algo que -o ProxyJump= no propaga en todos los contextos de invocación.
output "backend_ssh_command" {
  description = "Comando SSH para conectarse al backend a través del frontend (bastion)"
  value       = "ssh -i ${path.module}/${var.nombre_llave_ssh} -o ProxyJump=${var.usuario_ssh}@${aws_instance.frontend.public_ip} ${var.usuario_ssh}@${aws_instance.backend.private_ip}"
}

output "security_group_ids" {
  description = "IDs de los grupos de seguridad creados"
  value = {
    publico = aws_security_group.taller_iac_bootcamperu_publico.id
    privado = aws_security_group.taller_iac_bootcamperu_privado.id
    comun   = aws_security_group.taller_iac_bootcamperu_comun.id
  }
}
