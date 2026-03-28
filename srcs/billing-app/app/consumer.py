import os
import json
import pika
from app import db
from app.models import Order


def callback(app, ch, method, properties, body):
    data = json.loads(body.decode("utf-8"))
    with app.app_context():
        order = Order(
            user_id=str(data["user_id"]),
            number_of_items=int(data["number_of_items"]),
            total_amount=float(data["total_amount"]),
        )
        db.session.add(order)
        db.session.commit()
    ch.basic_ack(delivery_tag=method.delivery_tag)


def run_consumer(app):
    rabbit_host = os.getenv("RABBITMQ_HOST", "localhost")
    rabbit_port = int(os.getenv("RABBITMQ_PORT", "5672"))
    rabbit_user = os.getenv("RABBITMQ_USER", "guest")
    rabbit_password = os.getenv("RABBITMQ_PASSWORD", "guest")

    credentials = pika.PlainCredentials(rabbit_user, rabbit_password)
    params = pika.ConnectionParameters(host=rabbit_host, port=rabbit_port, credentials=credentials)

    connection = pika.BlockingConnection(params)
    channel = connection.channel()
    channel.queue_declare(queue="billing_queue", durable=True)
    channel.basic_consume(
        queue="billing_queue",
        on_message_callback=lambda ch, method, properties, body: callback(app, ch, method, properties, body),
    )
    channel.start_consuming()