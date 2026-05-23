# AGENTS.md — zEye

Maintain zEye as a safe Agent DVR USB Webcam CCTV stack.

Known good:
- Image: `mekayelanik/ispyagentdvr:latest`
- Internal port: `8090`
- Host port: `9292`
- Mapping: `9292:8090`
- Cloudflare origin: `http://127.0.0.1:9292`
- Primary camera: `/dev/video0`
- Fallback camera: `/dev/video2`
- Stable mode: root-camera

Safety:
- Do not bypass Agent DVR/iSpyConnect paid features.
- Do not commit secrets.
- Do not expose CCTV publicly without Cloudflare Access.
- Keep TURN UDP ports optional.

Validate:

```bash
find scripts tools -name "*.sh" -print0 | xargs -0 -n1 bash -n
docker compose config
git diff --check
bash scripts/security-check.sh
```
