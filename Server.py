import asyncio
import websockets
import json
import uuid

clients = {}     # ws -> player_id
positions = {}   # player_id -> {x,y,z}

async def broadcast(data):
    msg = json.dumps(data)
    for ws in list(clients.keys()):
        try:
            await ws.send(msg)
        except:
            pass

async def broadcast_players():
    await broadcast({
        "type": "players",
        "players": list(positions.keys())
    })

async def handler(ws):
    player_id = str(uuid.uuid4())[:8]
    clients[ws] = player_id
    positions[player_id] = {"x": 0, "y": 0, "z": 0}

    await ws.send(json.dumps({
        "type": "welcome",
        "player_id": player_id
    }))

    await broadcast_players()

    try:
        async for msg in ws:
            data = json.loads(msg)

            if data["type"] == "chat":
                await broadcast({
                    "type": "chat",
                    "message": f"{player_id}: {data['message']}"
                })

            if data["type"] == "position":
                positions[player_id] = {
                    "x": data["x"],
                    "y": data["y"],
                    "z": data["z"]
                }

                await broadcast({
                    "type": "position",
                    "player_id": player_id,
                    "x": data["x"],
                    "y": data["y"],
                    "z": data["z"]
                })

    except:
        pass
    finally:
        del clients[ws]
        del positions[player_id]
        await broadcast_players()

async def main():
    async with websockets.serve(handler, "0.0.0.0", 6074):
        print("Lobby Auto XYZ Server running on port 6074")
        await asyncio.Future()

asyncio.run(main())
