import json
import requests
import pika
from flask import Blueprint, request, jsonify
from app.config import INVENTORY_URL, RABBITMQ_HOST, RABBITMQ_PORT, RABBITMQ_USER, RABBITMQ_PASSWORD

gateway_bp = Blueprint("gateway", __name__)


@gateway_bp.route("/api/movies", defaults={"path": ""}, methods=["GET", "POST", "DELETE"])
@gateway_bp.route("/api/movies/<path:path>", methods=["GET", "PUT", "DELETE"])
def proxy_inventory(path):
    target = f"{INVENTORY_URL}/api/movies"
    if path:
        target = f"{target}/{path}"

    resp = requests.request(
        method=request.method,
        url=target,
        params=request.args,
        json=request.get_json(silent=True),
        timeout=10
    )
    excluded = {"content-encoding", "transfer-encoding", "connection"}
    headers = [(k, v) for k, v in resp.headers.items() if k.lower() not in excluded]
    return resp.content, resp.status_code, headers


@gateway_bp.route("/api/billing", methods=["POST"])
def post_billing():
    payload = request.get_json(silent=True)
    if payload is None:
        return jsonify({"error": "invalid JSON body"}), 400

    credentials = pika.PlainCredentials(RABBITMQ_USER, RABBITMQ_PASSWORD)
    params = pika.ConnectionParameters(host=RABBITMQ_HOST, port=RABBITMQ_PORT, credentials=credentials)
    connection = pika.BlockingConnection(params)
    channel = connection.channel()
    channel.queue_declare(queue="billing_queue", durable=True)
    channel.basic_publish(
        exchange="",
        routing_key="billing_queue",
        body=json.dumps(payload),
        properties=pika.BasicProperties(delivery_mode=2)
    )
    connection.close()

    return jsonify({"message": "Message posted"}), 202