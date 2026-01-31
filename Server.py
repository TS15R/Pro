import asyncio
import websockets
import json
import uuid

clients = {}     # websocket -> player_id
positions = {}   # player_id -> {x,y,z}

async def broadcast(data):
    message = json.dumps(data)
    for ws in list(clients.keys()):
        try:
            await ws.send(message)
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

            if data.get("type") == "chat":
                await broadcast({
                    "type": "chat",
                    "message": f"{player_id}: {data.get('message', '')}"
                })

            elif data.get("type") == "position":
                positions[player_id] = {
                    "x": data.get("x", 0),
                    "y": data.get("y", 0),
                    "z": data.get("z", 0)
                }

                await broadcast({
                    "type": "position",
                    "player_id": player_id,
                    "x": positions[player_id]["x"],
                    "y": positions[player_id]["y"],
                    "z": positions[player_id]["z"]
                })

    except:
        pass
    finally:
        if ws in clients:
            del clients[ws]
        if player_id in positions:
            del positions[player_id]
        await broadcast_players()

async def main():
    print("Lobby Auto XYZ Server running on port 6074")
    async with websockets.serve(handler, "0.0.0.0", 6074):
        await asyncio.Future()

asyncio.run(main())
