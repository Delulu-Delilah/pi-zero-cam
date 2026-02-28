# 📷 Pi Zero Cam

**Turn your Raspberry Pi Zero into a wireless IP camera in one command.**

Pi Zero Cam automatically detects your hardware, sets up a lightweight streaming server (MediaMTX), and broadcasts your camera feed over your Wi-Fi network. View it instantly in your browser (WebRTC) or VLC (RTSP).

---

## ✨ Features

- **🔍 Auto-detection** — Detects your Pi model and camera automatically
- **📡 Wireless Streaming** — Streams via high-performance RTSP and WebRTC
- **🚀 One-command install** — Single script handles downloading and setup
- **🔄 Auto-start** — Camera starts broadcasting automatically on every boot
- **🗑️ Clean uninstall** — Fully reversible, leaves no junk behind
- **📦 Zero hassle** — Uses precompiled binaries to get running in seconds

## 🛠 Compatibility

| Hardware | Status |
|---|---|
| Raspberry Pi Zero | ✅ Supported |
| Raspberry Pi Zero W | ✅ Supported |
| Raspberry Pi Zero 2 W | ✅ Supported |

| Camera | Status |
|---|---|
| Pi Camera Module v1 (OV5647) | ✅ Supported |
| Pi Camera Module v2 (IMX219) | ✅ Supported |
| Pi Camera Module 3 (IMX708) | ✅ Supported |
| Pi HQ Camera (IMX477) | ✅ Supported |
| USB Cameras (UVC) | ✅ Supported |

## ⚡ Quick Start

### Prerequisites

1. A Raspberry Pi Zero (any variant) with [Raspberry Pi OS Lite](https://www.raspberrypi.com/software/) flashed to an SD card
2. A camera module connected to the Pi
3. SSH access or a local terminal on the Pi

### Install

SSH into your Pi and run:

```bash
git clone https://github.com/Delulu-Delilah/pi-zero-cam.git
cd pi-zero-cam
sudo ./install.sh
```

Or one-liner:

```bash
curl -sSL https://raw.githubusercontent.com/Delulu-Delilah/pi-zero-cam/main/install.sh | sudo bash
```

The installer will:
1. ✅ Detect your Pi model
2. ✅ Detect your camera
3. ✅ Install required packages
6. ✅ Download and install `mediamtx` streaming server
7. ✅ Set up auto-start on boot

### After Install

1. Wait a few seconds for the camera to start streaming
2. Find your Pi's IP address (e.g., `192.168.1.50`)
3. **View in Browser (WebRTC):** Open `http://<pi-ip>:8889/cam`
4. **View in VLC (RTSP):** Open `rtsp://<pi-ip>:8554/cam`

## 🏗 How It Works

```
┌──────────────┐     Wi-Fi Network      ┌──────────────────┐
│   Camera     │ ) ) ) ) ) ) ) ) ) ) )  │   Your Computer  │
│   Module     │   Pi Zero streams      │   (host)         │
│              │   H.264 video via      │   Web Browser    │
│  CSI / USB   │   RTSP and WebRTC      │   or VLC         │
└──────────────┘                        └──────────────────┘
```

The Pi Zero connects to your existing Wi-Fi network and broadcasts its camera feed:

1. `libcamera-vid` (or `ffmpeg`) captures hardware-encoded H.264 video
2. Video is piped into `mediamtx`, a high-performance streaming server
3. You connect directly to the Pi over the network to view the ultra-low latency stream

## 🧪 Dry Run

Test the installer without making any changes:

```bash
sudo ./install.sh --dry-run
```

## 🗑️ Uninstall

To completely remove Pi Zero Cam and restore your original configuration:

```bash
sudo ./uninstall.sh
```

## 🔧 Troubleshooting

### Camera not detected during install

- Make sure the camera ribbon cable is firmly seated in both the camera module and Pi Zero
- For CSI cameras, the contacts should face the USB ports on the Pi Zero
- Try a different camera cable — the Pi Zero uses a narrower cable than full-size Pis

### Can't access the stream in the browser

- Make sure your computer is on the exact same Wi-Fi network as the Pi
- Try pinging the Pi: `ping <pi-ip>`
- Check the service status: `sudo systemctl status piwebcam`
- Check the streaming server logs: `journalctl -u piwebcam -n 50 -f`

### Low frame rate or poor quality

- The Pi Zero has limited CPU power; 640×480 at 30fps is the sweet spot
- Close other services to free up CPU: `sudo systemctl stop bluetooth`, etc.
- Ensure good lighting for the camera

### Service won't start

```bash
# Check status
sudo systemctl status piwebcam

# View detailed logs
journalctl -u piwebcam --no-pager -n 50

# Try running manually
sudo /usr/local/bin/piwebcam
```

## 📁 Project Structure

```
piwebcam/
├── install.sh          # Main installer (auto-detects everything)
├── uninstall.sh        # Clean uninstaller
├── piwebcam            # IP Camera launcher (installed to /usr/local/bin/)
├── piwebcam.service    # systemd service file
├── LICENSE             # MIT License
└── README.md           # This file
```

## 📝 License

[MIT License](LICENSE) — do whatever you want with it.

## 🙏 Credits

- [MediaMTX](https://github.com/bluenviron/mediamtx) — Next-gen RTSP / WebRTC server
- [Raspberry Pi Foundation](https://www.raspberrypi.org/) — for making awesome tiny computers
