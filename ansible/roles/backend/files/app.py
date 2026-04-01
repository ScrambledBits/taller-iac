from flask import Flask, jsonify
import socket, datetime

app = Flask(__name__)

@app.route("/api/health")
def health():
    return jsonify({
        "status": "ok",
        "host": socket.gethostname(),
        "deployed_by": "Ansible",
        "timestamp": str(datetime.datetime.utcnow())
    })

@app.route("/api/hello")
def hello():
    return jsonify({
        "message": "Hola desde WebStack!",
        "server": socket.gethostname()
    })

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
