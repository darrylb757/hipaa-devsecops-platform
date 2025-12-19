from flask import Flask, jsonify
import os

app = Flask(__name__)

VERSION = os.getenv("APP_VERSION", "0.1.0")

@app.get("/health")
def health():
    return jsonify(status="ok")

@app.get("/version")
def version():
    return jsonify(version=VERSION)

@app.get("/patients")
def patients():
    # Fake demo data: no PHI, no identifiers
    return jsonify([
        {"id": "demo-001", "status": "ACTIVE", "plan": "STANDARD"},
        {"id": "demo-002", "status": "INACTIVE", "plan": "STANDARD"},
        {"id": "demo-003", "status": "ACTIVE", "plan": "PREMIUM"}
    ])
