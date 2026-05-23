# zEye v4 Review

The observed deployment is functional but docker-compose.yml became syntactically invalid in v3. v4 fixes this by writing docker-compose.yml line-by-line.

Known-good facts:
- Agent DVR container runs healthy.
- Agent DVR internal UI listens on 8090.
- Host 9292 -> container 8090 is correct.
- /dev/video0 supports MJPEG and YUYV up to 1280x720.
- /dev/video2 supports MJPEG/YUYV with more formats.
- /dev/video1 and /dev/video3 are metadata/unsupported endpoints.
- CPU decoder is recommended in VMware/Docker.
- Root-camera mode is the stable working mode.
