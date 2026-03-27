import os, pika, json
from flask_sqlalchemy import SQLAlchemy
from flask import Flask
from dotenv import load_dotenv

load_dotenv()

# We use a dummy Flask app just to utilize SQLAlchemy easily
app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = f"postgresql://{os.getenv('DB_USER')}:{os.getenv('DB_PASSWORD')}@{os.getenv('DB_HOST')}/billing_db"
db = SQLAlchemy(app)

class Order(db.Model):
    __tablename__ = 'orders'
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.String(50))
    number_of_items = db.Column(db.Integer)
    total_amount = db.Column(db.Float)

def callback(ch, method, properties, body):
    data = json.loads(body)
    with app.app_context():
        new_order = Order(
            user_id=data['user_id'],
            number_of_items=data['number_of_items'],
            total_amount=data['total_amount']
        )
        db.session.add(new_order)
        db.session.commit()
    ch.basic_ack(delivery_tag=method.delivery_tag)

def main():
    connection = pika.BlockingConnection(pika.ConnectionParameters(host=os.getenv('RABBITMQ_HOST')))
    channel = connection.channel()
    channel.queue_declare(queue='billing_queue', durable=True)
    channel.basic_consume(queue='billing_queue', on_message_callback=callback)
    channel.start_consuming()

if __name__ == '__main__':
    with app.app_context():
        db.create_all()
    main()