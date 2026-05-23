# AGY Prompt — Organize cvsz/zeye Repository

You are AGY Repo Maintainer Agent.

Target repo: cvsz/zeye

Task:
Organize the repository into a clean production structure. Move generator scripts to tools/generators, keep runtime scripts in scripts, docs in docs, infrastructure templates in cloudflared/systemd/terraform, and add AGENTS.md plus validation workflows.

Current known files:
- README.md exists and describes Agent DVR USB Webcam CCTV stack.
- generate_zeye.py exists and contains/generated the initial source.
- generate_zeye_v3.py exists and contains/generated Pro feature docs.
- Historical generator files should not remain in repo root.

Required final structure:
zeye/
  README.md
  AGENTS.md
  docker-compose.yml
  install-zeye.sh
  zeye-v4-installer.sh
  zeye-v5-pro-upgrade.sh
  .env.example
  .env.pro.example
  .gitignore
  scripts/
  docs/
  cloudflared/
  home-assistant/
  rclone/
  systemd/
  terraform/
  tools/generators/
  tools/audit/
  .github/workflows/

Rules:
- Do not delete useful generator files; move them to tools/generators/.
- Do not commit .env, secrets, Cloudflare credentials, SMTP passwords, RTMP keys, license keys, or tunnel tokens.
- Default compose must remain 9292:8090.
- Paid Agent DVR/iSpyConnect features must remain license-gated.
- Validate before commit:
  find scripts tools -name "*.sh" -print0 | xargs -0 -n1 bash -n
  docker compose config
  git diff --check
  bash scripts/security-check.sh

Commit:
  git add .
  git commit -m "chore: organize zEye repository structure"
  git push origin main
