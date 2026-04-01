# Rol: backend

Instala Python 3, pip y Flask, despliega la aplicación Flask e instala el servicio systemd que la mantiene en ejecución.

## Descripción

- Instala `python3` y `python3-pip` desde apt
- Instala Flask mediante pip3
- Crea el directorio de la aplicación y copia `app.py`
- Instala el servicio systemd `flask-app` y lo habilita para arranque automático

> **Nota de red:** Esta instancia opera en la **subnet privada** sin IP pública.
> Ansible la alcanza a través del frontend como bastion host usando ProxyJump.
> El acceso SSH directo desde internet no es posible por diseño.

## Tareas

| Tarea | Descripción |
|---|---|
| Instalar Python 3 y pip | Instala `python3` y `python3-pip` desde apt |
| Instalar Flask | Instala Flask con pip3 |
| Crear directorio de la app | Crea `{{ directorio_app }}` con permisos 755 |
| Copiar app.py | Copia el archivo de la aplicación al servidor |
| Instalar servicio systemd | Renderiza `flask-app.service.j2` en `/etc/systemd/system/` |

## Variables

| Variable | Predeterminado | Descripción |
|---|---|---|
| `directorio_app` | `/opt/webstack-app` | Ruta donde se despliega la aplicación |
| `archivo_app` | `app.py` | Nombre del archivo principal de la aplicación |
| `nombre_servicio` | `flask-app` | Nombre del servicio systemd |

## Templates

| Archivo | Destino |
|---|---|
| `flask-app.service.j2` | `/etc/systemd/system/{{ nombre_servicio }}.service` |

## Handlers

| Handler | Acción |
|---|---|
| `iniciar {{ nombre_servicio }}` | Recarga systemd, inicia y habilita el servicio |

## Dependencias

El rol `comun` debe ejecutarse antes.

## Licencia

MIT-0
