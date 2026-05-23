# zEye

Agent DVR USB webcam CCTV stack for Ubuntu + Docker.

## Working URLs

- Local: http://127.0.0.1:9292
- LAN: http://192.168.1.104:9292 or http://192.168.1.100:9292
- Cloudflare origin: http://127.0.0.1:9292

## Agent DVR UI

Use:

```text
Video Source:
  Source Type = Local Device
  Device      = /dev/video0

Advanced:
  Decoder     = CPU
  GPU Decoder = Default
  VLC Options = blank
```

## Notes

`ffmpeg -list_formats` can end with "Immediate exit requested" after listing MJPEG/YUYV formats. That is normal.
