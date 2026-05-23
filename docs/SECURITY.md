# Security Baseline

## Core Safety Principles

1. **No Secrets in Git**: 
   - Never commit `.env` or `.env.pro`.
   - Never commit `cloudflared/credentials.json` or any `*.pem` keys.
   - Use the provided `.example` files as your safe baseline.

2. **Cloudflare Access Required**:
   - By default, your CCTV streams are protected behind `cctv.zeaz.dev`.
   - You MUST enforce a Zero Trust Access Policy (like requiring an Email OTP) to prevent direct internet exposure.

3. **License and Subscription Compliance**:
   - Advanced UI streaming, HD/4K remote playback, and rich push notifications natively require an active iSpyConnect/Agent DVR Pro subscription.
   - We strictly adhere to these licensing constraints. Do not commit or use spoofing scripts.

4. **CCTV Access Safety Baseline**:
   - The primary stack connects via `http://127.0.0.1:9292`.
   - Never expose port `8090` or `9292` directly on your physical firewall/router unless wrapped inside a secure tunnel or VPN.

## Secret Rotation Protocol

If you accidentally share logs or commit a configuration file containing sensitive data:
1. **Cloudflare Tokens**: Revoke the tunnel token immediately in the Cloudflare Zero Trust dashboard and generate a new one.
2. **SMTP Passwords**: Regenerate the app password with your email provider (e.g., Google or Microsoft).
3. **RTMP Keys**: Cycle your broadcast keys via YouTube/Twitch immediately.
4. Scrub your local git history using `git filter-repo` or immediately force-delete the compromised branch if exposed publicly.
