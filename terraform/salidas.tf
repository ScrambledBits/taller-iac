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

# El backend no tiene IP pública. La conexión SSH se realiza a través del
# frontend como bastion host usando la opción ProxyJump.
output "backend_ssh_command" {
  description = "Comando SSH para conectarse al backend a través del frontend (bastion)"
  value       = "ssh -i ${path.module}/${var.nombre_llave_ssh} -o ProxyJump=${var.usuario_ssh}@${aws_instance.frontend.public_ip} ${var.usuario_ssh}@${aws_instance.backend.private_ip}"
}
