# RTMP Streaming

Agent DVR allows you to push or pull RTMP streams. This is useful for streaming your CCTV feed to external platforms.
**Note:** RTMP broadcasting functionality natively requires an active Agent DVR Pro license.

## Configuration Warnings

1. Obtain your RTMP Stream URL and Stream Key from your broadcast platform.
2. Store your stream key safely in `.env.pro` under `RTMP_STREAM_KEY`.
3. Configure the Agent DVR interface directly using your credentials.
4. **CRITICAL:** Never commit your stream key or `.env.pro` file to any git repository!
