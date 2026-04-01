# Rol: frontend

Instala y configura nginx en la instancia pública para servir el sitio estático y actuar como reverse proxy hacia la aplicación Flask del backend.

## Descripción

- Instala nginx
- Crea el directorio webroot y despliega los archivos estáticos (`index.html`, `api.js`)
- Configura nginx como reverse proxy: las peticiones a `/api/` se redirigen hacia `app_private_ip:5000`
- Deshabilita el sitio `default` de nginx y habilita el sitio del proyecto

## Tareas

| Tarea | Descripción |
|---|---|
| Instalar nginx | Instala nginx desde apt |
| Crear directorio webroot | Crea `{{ directorio_web }}` con permisos 755 |
| Copiar página estática | Renderiza `index.html.j2` en el webroot |
| Copiar Javascript | Renderiza `api.js.j2` en el webroot |
| Configurar reverse proxy | Renderiza `nginx.conf.j2` en `sites-available` |
| Habilitar sitio | Crea el enlace simbólico en `sites-enabled` |
| Deshabilitar sitio default | Elimina el enlace del sitio default de nginx |

## Variables

| Variable | Predeterminado | Descripción |
|---|---|---|
| `directorio_web` | `/var/www/bootcamperu` | Ruta del webroot de nginx |
| `nombre_sitio` | `bootcamperu` | Nombre del sitio en `sites-available/sites-enabled` |
| `app_private_ip` | — | IP privada del backend; pasada como `--extra-vars` desde Terraform |

## Templates

| Archivo | Destino |
|---|---|
| `nginx.conf.j2` | `/etc/nginx/sites-available/{{ nombre_sitio }}` |
| `index.html.j2` | `{{ directorio_web }}/index.html` |
| `api.js.j2` | `{{ directorio_web }}/api.js` |

## Dependencias

El rol `comun` debe ejecutarse antes.

## Licencia

MIT-0
