# stoat-inabox

One-click [Stoat](https://stoat.chat) self-hosted chat for Unraid. Installs everything automatically as a VM.

> **Unraid only.** For other systems, use the [official Stoat self-hosted setup](https://github.com/stoatchat/self-hosted) instead.

## Requirements

- Virtualization enabled (VT-x or AMD-V)
- Unraid VM Manager enabled (Settings → VM Manager)
- under construction

## Installation

under construction

## Updating Stoat

SSH into the VM and run:

```bash
cd /opt/stoat && git pull && docker compose pull && docker compose up -d
```

## Support

- [stoat-inabox issues](https://github.com/hawwwwwk/stoat-inabox/issues)
- [Stoat self-hosted docs](https://github.com/stoatchat/self-hosted)