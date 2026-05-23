# HD and 4K Playback

Deploying high-resolution HD (1080p) or 4K (2160p) cameras drastically changes system requirements.
**Note:** Native HD/4K web playback and remote streaming optimization features require an iSpyConnect Pro license.

## Infrastructure Constraints

- **CPU / GPU**: 4K encoding and decoding requires significant computational power. If GPU acceleration is not perfectly configured or supported by your hardware, 4K streams will cause severe CPU throttling and latency.
- **Network**: Ensure your local gigabit network can handle the sustained bandwidth required for multiple 4K cameras. Wi-Fi cameras are highly discouraged for 4K.
- **Storage**: High-resolution video will fill your storage drives exponentially faster. Ensure you have massive HDD space mapped to `/opt/zeye/media` or aggressive storage retention policies enabled.
- **Validation**: Before scaling up, run `./scripts/resource-check.sh` to ensure your system isn't already buckling under the load.
