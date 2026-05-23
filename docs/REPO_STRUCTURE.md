# zEye Repository Structure

```text
zeye/
├── README.md                         # Main project overview
├── docker-compose.yml                # Agent DVR runtime stack
├── install-zeye.sh                   # Main install script
├── zeye-v4-installer.sh              # Stable repair/install script
├── zeye-v5-pro-upgrade.sh            # Licensed pro-feature readiness
├── .env.example                      # Safe base env template
├── .env.pro.example                  # Safe pro-feature env template
├── scripts/                          # Operational scripts
│   ├── health.sh
│   ├── doctor.sh
│   ├── camera-permissions.sh
│   ├── restart.sh
│   ├── up.sh
│   ├── down.sh
│   ├── logs.sh
│   ├── update-agentdvr.sh
│   ├── cloud-backup.sh
│   ├── mqtt-test.sh
│   ├── cloudflare-check.sh
│   ├── security-check.sh
│   └── backup-config.sh
├── docs/                             # Operator documentation
│   ├── QUICKSTART.md
│   ├── DEPLOYMENT.md
│   ├── TROUBLESHOOTING.md
│   ├── PRO_FEATURES_SETUP.md
│   ├── CLOUDFLARE_ACCESS.md
│   ├── EMAIL_NOTIFICATIONS.md
│   ├── USER_PERMISSIONS.md
│   ├── AI_SETUP.md
│   ├── RTMP_STREAMING.md
│   ├── SMART_HOME.md
│   ├── CLOUD_BACKUP.md
│   ├── SECURITY.md
│   ├── LICENSE_FEATURES.md
│   └── REPO_STRUCTURE.md
├── cloudflared/                      # Cloudflare Tunnel templates only
├── home-assistant/                   # Smart home examples
├── rclone/                           # Cloud backup docs
├── systemd/                          # Optional service/timer units
├── terraform/                        # Optional IaC examples only
├── tools/
│   ├── generators/                   # Historical generator scripts
│   └── audit/                        # Repo audit helpers
└── .github/workflows/                # CI validation
```

## Rules

- Root directory stays small.
- Runtime scripts go in `scripts/`.
- Operator docs go in `docs/`.
- Historical generation helpers go in `tools/generators/`.
- No secrets in git.
- No `.env`, Cloudflare credentials, SMTP passwords, RTMP keys, or tunnel tokens.
- Paid iSpyConnect/Agent DVR features must remain license/subscription-gated.
