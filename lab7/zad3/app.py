from flask import Flask, jsonify
from pymongo import MongoClient

app = Flask(__name__)

# connect to the 'test' database on the 'db' host
client = MongoClient("mongodb://db:27017/")
db = client["test"]
collection = db["users"]

@app.route("/users", methods=["GET"])
def get_users():
    # return all records from 'users' collection skipping _id field
    users = list(collection.find({}, {"_id": 0}))
    return jsonify(users)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
