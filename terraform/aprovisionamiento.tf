locals {
  prefijo_proyecto = replace(var.nombre_proyecto, "-", "_")
  ruta_llave_ssh   = "${path.module}/${var.nombre_llave_ssh}"
  ansible_dir      = "${path.module}/../ansible"
  ruta_inventario  = "${path.module}/../ansible/inventario_terraform.yaml"
}

# Genera el inventario de Ansible con las IPs de las instancias creadas por Terraform.
# El backend usa la IP privada junto con ProxyJump a través del frontend,
# ya que no tiene IP pública al estar en la subnet privada.
# NOTA: Este archivo se sobreescribe en cada `terraform apply`. No editar manualmente.
resource "local_file" "ansible_inventory" {
  filename        = local.ruta_inventario
  file_permission = "0644"
  content         = <<-YAML
    # Archivo generado automáticamente por Terraform al ejecutar `terraform apply`.
    # NO editar manualmente — los cambios se sobreescribirán en el próximo apply.
    all:
      vars:
        ansible_user: ${var.usuario_ssh}
        ansible_ssh_private_key_file: ${local.ruta_llave_ssh}
      children:
        frontend:
          hosts:
            web-server:
              ansible_host: ${aws_instance.frontend.public_ip}
        backend:
          hosts:
            backend-server:
              # El backend no tiene IP pública; se accede vía ProxyJump a través del frontend.
              ansible_host: ${aws_instance.backend.private_ip}
              ansible_ssh_common_args: >-
                -o ProxyJump=${var.usuario_ssh}@${aws_instance.frontend.public_ip}
                -o StrictHostKeyChecking=no
    YAML

  depends_on = [aws_instance.frontend, aws_instance.backend]
}

# Provisioner que espera a que SSH esté disponible en ambas instancias antes
# de ejecutar Ansible. El backend se alcanza a través del frontend como bastion.
resource "terraform_data" "ansible_provisioning" {
  # Re-ejecutar el aprovisionamiento si cambian las IPs de las instancias.
  triggers_replace = [
    aws_instance.frontend.public_ip,
    aws_instance.backend.private_ip,
  ]

  # Verificar que SSH está listo en el frontend (acceso directo).
  provisioner "remote-exec" {
    inline = ["echo 'SSH listo: frontend'"]
    connection {
      type        = "ssh"
      user        = var.usuario_ssh
      private_key = tls_private_key.bootcamp.private_key_pem
      host        = aws_instance.frontend.public_ip
    }
  }

  # Verificar que SSH está listo en el backend usando el frontend como bastion.
  # El backend no tiene IP pública, por lo que la conexión se tuneliza a través
  # del frontend con las mismas credenciales SSH.
  provisioner "remote-exec" {
    inline = ["echo 'SSH listo: backend'"]
    connection {
      type                = "ssh"
      user                = var.usuario_ssh
      private_key         = tls_private_key.bootcamp.private_key_pem
      host                = aws_instance.backend.private_ip
      bastion_host        = aws_instance.frontend.public_ip
      bastion_user        = var.usuario_ssh
      bastion_private_key = tls_private_key.bootcamp.private_key_pem
    }
  }

  # Ejecutar el playbook de Ansible una vez confirmado el acceso SSH.
  # Se pasa la IP privada del backend como variable para que nginx la use en su configuración.
  provisioner "local-exec" {
    command = <<-CMD
      ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook \
        --inventory ${local.ruta_inventario} \
        --private-key ${local.ruta_llave_ssh} \
        --extra-vars "app_private_ip=${aws_instance.backend.private_ip}" \
        ${local.ansible_dir}/playbook.yaml
    CMD
  }

  depends_on = [local_file.ansible_inventory, local_sensitive_file.private_key]
}
