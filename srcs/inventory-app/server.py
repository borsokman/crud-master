import os
from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from dotenv import load_dotenv

load_dotenv()

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = f"postgresql://{os.getenv('DB_USER')}:{os.getenv('DB_PASSWORD')}@{os.getenv('DB_HOST')}:{os.getenv('DB_PORT')}/{os.getenv('DB_NAME')}"
db = SQLAlchemy(app)

class Movie(db.Model):
    __tablename__ = 'movies'
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(100), nullable=False)
    description = db.Column(db.Text)

with app.app_context():
    db.create_all()

@app.route('/api/movies', methods=['GET'])
def get_movies():
    title = request.args.get('title')
    if title:
        movies = Movie.query.filter(Movie.title.contains(title)).all()
    else:
        movies = Movie.query.all()
    return jsonify([{'id': m.id, 'title': m.title, 'description': m.description} for m in movies])

@app.route('/api/movies', methods=['POST'])
def add_movie():
    data = request.json
    new_movie = Movie(title=data['title'], description=data.get('description'))
    db.session.add(new_movie)
    db.session.commit()
    return jsonify({'id': new_movie.id}), 201

# Add DELETE, PUT, and single GET routes similarly...

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)