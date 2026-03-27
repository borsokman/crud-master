import os, requests, pika, json
from flask import Flask, request, jsonify

app = Flask(__name__)

INVENTORY_URL = "http://192.168.1.20:8080/api/movies"

@app.route('/api/movies', defaults={'path': ''}, methods=['GET', 'POST', 'DELETE'])
@app.route('/api/movies/<path:path>', methods=['GET', 'PUT', 'DELETE'])
def proxy_inventory(path):
    url = f"{INVENTORY_URL}/{path}" if path else INVENTORY_URL
    resp = requests.request(
        method=request.method,
        url=url,
        params=request.args,
        json=request.json
    )
    return (resp.content, resp.status_code, resp.headers.items())

@app.route('/api/billing', methods=['POST'])
def post_billing():
    connection = pika.BlockingConnection(pika.ConnectionParameters(host='192.168.1.30'))
    channel = connection.channel()
    channel.queue_declare(queue='billing_queue', durable=True)
    channel.basic_publish(
        exchange='',
        routing_key='billing_queue',
        body=json.dumps(request.json),
        properties=pika.BasicProperties(delivery_mode=2) # Persistent message
    )
    connection.close()
    return jsonify({"message": "Message posted"}), 202

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)