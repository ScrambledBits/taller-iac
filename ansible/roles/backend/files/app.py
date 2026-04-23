# Aplicación Flask mínima para el taller de IaC — BootcampPeru.
#
# Expone dos endpoints HTTP que demuestran que el backend está activo y responde:
#   GET /api/health  — devuelve el estado del servicio, el hostname de la instancia
#                      y la hora UTC actual. Usado por el frontend para el health check.
#   GET /api/hello   — devuelve un mensaje de saludo con el hostname del servidor.
#
# Flask escucha en 0.0.0.0:5000, lo que significa que acepta conexiones en todas
# las interfaces de red de la instancia, no solo en localhost. En este proyecto
# el acceso está restringido por el security group privado: solo el frontend puede
# alcanzar el puerto 5000, nunca un cliente externo directamente.
from flask import Flask, jsonify
import socket, datetime

app = Flask(__name__)

@app.route("/api/health")
def health():
    return jsonify({
        "status": "ok",
        "host": socket.gethostname(),
        "deployed_by": "Ansible",
        # datetime.now(timezone.utc) es la forma correcta en Python 3.12+.
        # datetime.utcnow() fue deprecada porque devuelve una fecha "naive" (sin zona horaria),
        # lo que puede generar confusión al comparar fechas o al serializar a JSON.
        "timestamp": str(datetime.datetime.now(datetime.timezone.utc))
    })

@app.route("/api/hello")
def hello():
    return jsonify({
        "message": "Hola desde WebStack!",
        "server": socket.gethostname()
    })

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
