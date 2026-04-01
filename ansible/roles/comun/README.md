# Rol: comun

Aplica la configuración base del sistema operativo en todas las instancias del proyecto antes de que se ejecuten los roles específicos de cada servicio.

## Descripción

Realiza una actualización completa del sistema operativo mediante `apt`, incluyendo limpieza de paquetes obsoletos. Se aplica tanto al frontend como al backend.

## Tareas

| Tarea | Descripción |
|---|---|
| Actualizar sistema | `apt update && apt upgrade` con limpieza automática de paquetes |

## Variables

Este rol no expone variables configurables.

## Dependencias

Ninguna. Es el primer rol en ejecutarse en el playbook.

## Uso

```yaml
- hosts: all
  become: true
  roles:
    - comun
```

## Licencia

MIT-0
