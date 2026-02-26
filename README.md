# stoat-inabox

One-click [Stoat](https://stoat.chat) self-hosted chat for Unraid. Installs everything automatically as a VM.

> **Unraid only.** For other systems, use the [official Stoat self-hosted setup](https://github.com/stoatchat/self-hosted) instead.

## Requirements

- Virtualization enabled (VT-x or AMD-V)
- Unraid VM Manager enabled (Settings → VM Manager)
- UNDER CONSTRUCTION

## Installation

UNDER CONSTRUCTION

##### Example Deployment (please use Unraid's appstore instead)

```
docker run -d \
  --name stoat-inabox \
  --network host \
  --restart unless-stopped \
  -v /var/run/libvirt/libvirt-sock:/var/run/libvirt/libvirt-sock \
  -v /mnt/user/appdata/stoat:/appdata \
  -v /mnt/user/domains:/mnt/user/domains \
  -e DOMAIN=stoat.ethxn.xyz \
  -e VMNAME=Stoat \
  -e VM_CPUS=2 \
  -e VM_RAM=6144 \
  -e VM_DISK=40 \
  -e PROXY_PORT=8456 \
  -e APPDATA_HOST=/mnt/user/appdata/stoat \
  -e DOMAINS_HOST=/mnt/user/domains \
  -e CHECK_INTERVAL=15 \
  ethxn/stoat-inabox:latest
```

When running the cloud-init (it may take up to 15 minutes to fully deploy everything), if you want to check the progress of the container, you can via `virsh --connect qemu:///system console Stoat` (replace "Stoat" with your VM name)

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