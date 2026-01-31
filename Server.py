#!/usr/bin/env python3
"""
Multiplayer Server for TurboWarp Game
รองรับการเล่นหลายคนพร้อมกัน
"""

import asyncio
import websockets
import json
import logging
from datetime import datetime

# ตั้งค่า logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# เก็บข้อมูลผู้เล่นทั้งหมด
players = {}
# เก็บข้อมูลสถานะเกม
game_state = {
    'players': {},
    'projectiles': [],
    'enemies': []
}

class GameServer:
    def __init__(self):
        self.connections = set()
        self.player_data = {}
        
    async def register(self, websocket):
        """ลงทะเบียนผู้เล่นใหม่"""
        self.connections.add(websocket)
        player_id = id(websocket)
        
        # สร้างข้อมูลผู้เล่นใหม่
        self.player_data[player_id] = {
            'id': player_id,
            'x': 0,
            'y': 0,
            'direction': 90,
            'costume': 1,
            'health': 100,
            'score': 0,
            'connected_at': datetime.now().isoformat()
        }
        
        logger.info(f"Player {player_id} connected. Total players: {len(self.connections)}")
        
        # ส่งข้อมูล player ID กลับไป
        await websocket.send(json.dumps({
            'type': 'welcome',
            'player_id': player_id,
            'message': 'Connected to game server'
        }))
        
        # ส่งข้อมูลผู้เล่นทั้งหมดให้ผู้เล่นใหม่
        await self.send_all_players(websocket)
        
        # แจ้งผู้เล่นอื่นว่ามีผู้เล่นใหม่
        await self.broadcast({
            'type': 'player_joined',
            'player': self.player_data[player_id]
        }, exclude=websocket)
        
    async def unregister(self, websocket):
        """ยกเลิกการลงทะเบียนผู้เล่น"""
        self.connections.discard(websocket)
        player_id = id(websocket)
        
        if player_id in self.player_data:
            # แจ้งผู้เล่นอื่นว่ามีคนออก
            await self.broadcast({
                'type': 'player_left',
                'player_id': player_id
            })
            
            del self.player_data[player_id]
            logger.info(f"Player {player_id} disconnected. Total players: {len(self.connections)}")
    
    async def send_all_players(self, websocket):
        """ส่งข้อมูลผู้เล่นทั้งหมดให้กับผู้เล่นที่เชื่อมต่อใหม่"""
        await websocket.send(json.dumps({
            'type': 'all_players',
            'players': list(self.player_data.values())
        }))
    
    async def broadcast(self, message, exclude=None):
        """ส่งข้อความไปยังผู้เล่นทั้งหมด"""
        if self.connections:
            message_json = json.dumps(message)
            tasks = []
            for conn in self.connections:
                if conn != exclude:
                    tasks.append(conn.send(message_json))
            
            if tasks:
                await asyncio.gather(*tasks, return_exceptions=True)
    
    async def handle_message(self, websocket, message):
        """จัดการข้อความที่ได้รับจากผู้เล่น"""
        try:
            data = json.loads(message)
            msg_type = data.get('type')
            player_id = id(websocket)
            
            if msg_type == 'update_position':
                # อัปเดตตำแหน่งผู้เล่น
                if player_id in self.player_data:
                    self.player_data[player_id]['x'] = data.get('x', 0)
                    self.player_data[player_id]['y'] = data.get('y', 0)
                    self.player_data[player_id]['direction'] = data.get('direction', 90)
                    
                    # ส่งข้อมูลให้ผู้เล่นอื่น
                    await self.broadcast({
                        'type': 'player_moved',
                        'player_id': player_id,
                        'x': data.get('x'),
                        'y': data.get('y'),
                        'direction': data.get('direction')
                    }, exclude=websocket)
            
            elif msg_type == 'update_costume':
                # อัปเดตชุดของผู้เล่น
                if player_id in self.player_data:
                    self.player_data[player_id]['costume'] = data.get('costume', 1)
                    
                    await self.broadcast({
                        'type': 'player_costume_changed',
                        'player_id': player_id,
                        'costume': data.get('costume')
                    }, exclude=websocket)
            
            elif msg_type == 'shoot':
                # ส่งข้อมูลการยิง
                await self.broadcast({
                    'type': 'player_shot',
                    'player_id': player_id,
                    'x': data.get('x'),
                    'y': data.get('y'),
                    'direction': data.get('direction')
                }, exclude=websocket)
            
            elif msg_type == 'update_health':
                # อัปเดตพลังชีวิต
                if player_id in self.player_data:
                    self.player_data[player_id]['health'] = data.get('health', 100)
                    
                    await self.broadcast({
                        'type': 'player_health_changed',
                        'player_id': player_id,
                        'health': data.get('health')
                    }, exclude=websocket)
            
            elif msg_type == 'update_score':
                # อัปเดตคะแนน
                if player_id in self.player_data:
                    self.player_data[player_id]['score'] = data.get('score', 0)
                    
                    await self.broadcast({
                        'type': 'player_score_changed',
                        'player_id': player_id,
                        'score': data.get('score')
                    }, exclude=websocket)
            
            elif msg_type == 'chat':
                # ส่งข้อความแชท
                await self.broadcast({
                    'type': 'chat',
                    'player_id': player_id,
                    'message': data.get('message', '')
                }, exclude=websocket)
            
            elif msg_type == 'ping':
                # ตอบกลับ ping
                await websocket.send(json.dumps({'type': 'pong'}))
                
        except json.JSONDecodeError:
            logger.error(f"Invalid JSON received: {message}")
        except Exception as e:
            logger.error(f"Error handling message: {e}")
    
    async def handler(self, websocket, path):
        """จัดการการเชื่อมต่อของผู้เล่น"""
        await self.register(websocket)
        try:
            async for message in websocket:
                await self.handle_message(websocket, message)
        except websockets.exceptions.ConnectionClosed:
            pass
        finally:
            await self.unregister(websocket)

async def main():
    """เริ่มต้นเซิร์ฟเวอร์"""
    server = GameServer()
    
    # เริ่มเซิร์ฟเวอร์ที่ port 8765
    async with websockets.serve(server.handler, "0.0.0.0", 6074):
        logger.info("🎮 Game Server started on ws://0.0.0.0:6074")
        logger.info("📡 Waiting for players to connect...")
        logger.info("Press Ctrl+C to stop the server")
        
        # รอให้เซิร์ฟเวอร์ทำงานตลอด
        await asyncio.Future()

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        logger.info("\n👋 Server stopped by user")