# 📷 Pi Zero Cam

**Turn your Raspberry Pi Zero into a plug-and-play USB webcam in one command.**

Pi Zero Cam automatically detects your hardware, configures USB gadget mode, and sets up a camera stream that works as a standard webcam on Windows, macOS, and Linux — no drivers required.

---

## ✨ Features

- **🔍 Auto-detection** — Detects your Pi model and camera automatically
- **🔌 Plug-and-play** — Shows up as a standard USB webcam on any OS
- **🚀 One-command install** — Single script handles everything
- **🔄 Auto-start** — Webcam starts automatically on every boot
- **🗑️ Clean uninstall** — Fully reversible, no leftover config
- **📦 Zero dependencies** — Just needs Raspberry Pi OS

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
| USB Cameras (UVC-compatible) | ✅ Supported |

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
4. ✅ Configure USB gadget mode
5. ✅ Build and install `uvc-gadget`
6. ✅ Set up auto-start on boot

### After Install

1. **Reboot** the Pi: `sudo reboot`
2. **Connect** the Pi's **data** micro-USB port to your computer
3. **Open** any camera app — your Pi is now a webcam! 📷

> **Important:** Use the **data** micro-USB port (usually labeled "USB"), not the power-only port.

## 🏗 How It Works

```
┌──────────────┐     USB Cable      ┌──────────────────┐
│   Camera     │───────────────────▶│   Your Computer  │
│   Module     │  Pi Zero (gadget)  │   (host)         │
│              │  acts as a USB     │   Sees a webcam  │
│  CSI / USB   │  webcam device     │   📷             │
└──────────────┘                    └──────────────────┘
```

The Pi Zero's USB OTG port supports **gadget mode**, allowing it to present itself as a USB device to the host computer. Pi Zero Cam:

1. Configures the Linux USB gadget subsystem (`configfs`) to create a UVC (USB Video Class) device
2. Captures video from the connected camera via V4L2
3. Streams the video through the USB gadget to the host computer

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

### Computer doesn't see a webcam after reboot

- Make sure you're using the **data** USB port, not the power-only port
- Try a different USB cable — some cables are charge-only (no data)
- Check the service status: `sudo systemctl status piwebcam`
- View logs: `journalctl -u piwebcam -f`

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
pi-zero-cam/
├── install.sh          # Main installer (auto-detects everything)
├── uninstall.sh        # Clean uninstaller
├── piwebcam            # UVC gadget launcher (installed to /usr/local/bin/)
├── piwebcam.service    # systemd service file
├── LICENSE             # MIT License
└── README.md           # This file
```

## 📝 License

[MIT License](LICENSE) — do whatever you want with it.

## 🙏 Credits

- [uvc-gadget](https://github.com/climberhunt/uvc-gadget) — UVC gadget userspace tool
- [Raspberry Pi Foundation](https://www.raspberrypi.org/) — for making awesome tiny computers
- [showmewebcam](https://github.com/showmewebcam/showmewebcam) — inspiration for this project
