from flask import Flask, request, jsonify

app = Flask(__name__)

players = {}

@app.route("/update", methods=["POST"])
def update():
    data = request.json
    players[data["id"]] = {
        "x": data["x"],
        "y": data["y"]
    }
    return jsonify(players)

app.run(host="0.0.0.0", port=6074)
