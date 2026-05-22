# Terraform notes for cctv.zeaz.dev

This folder intentionally contains examples only. Do not commit Cloudflare tokens, zone IDs, account IDs, or tunnel credentials.

Cloudflare Tunnel public hostname should generally expose:

```text
https://cctv.zeaz.dev -> http://127.0.0.1:9292
```

Do not run `terraform apply` until the operator confirms the Cloudflare zone/account/tunnel resources are managed by this repo.
