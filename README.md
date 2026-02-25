# stoat-inabox

One-click [Stoat](https://stoat.chat) self-hosted chat for Unraid. Installs everything automatically as a VM.

> **Unraid only.** For other systems, use the [official Stoat self-hosted setup](https://github.com/stoatchat/self-hosted) instead.

## Requirements

- Virtualization enabled (VT-x or AMD-V)
- Unraid VM Manager enabled (Settings → VM Manager)
- UNDER CONSTRUCTION

## Installation

UNDER CONSTRUCTION

## Support

- [stoat-inabox issues](https://github.com/hawwwwwk/stoat-inabox/issues)
- [stoat self-hosted docs](https://github.com/stoatchat/self-hosted)
- [Docker Image](https://hub.docker.com/r/ethxn/stoat-inabox)

## Uninstall Previous Version

- Stop and remove the VM
```
virsh --connect qemu:///system destroy Stoat
virsh --connect qemu:///system undefine Stoat
```
- Wipe all data
```
rm -rf /mnt/user/appdata/stoat
rm -rf /mnt/user/domains/stoat
```