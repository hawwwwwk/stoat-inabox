#!/bin/bash
set -e

# ─── Config ───────────────────────────────────────────────────────────────────
DOMAIN="${DOMAIN:-stoat.yourdomain.com}"
VMNAME="${VMNAME:-Stoat}"
VM_CPUS="${VM_CPUS:-2}"
VM_RAM="${VM_RAM:-4096}"
VM_DISK="${VM_DISK:-40}"
DOMAINS="/mnt/user/domains"
DOMAINS_HOST="${DOMAINS_HOST:-/mnt/user/domains}"
APPDATA="/appdata"
APPDATA_HOST="${APPDATA_HOST:-/mnt/user/appdata/stoat}"
CHECK_INTERVAL="${CHECK_INTERVAL:-15}"

UBUNTU_IMAGE_URL="https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
DISK_PATH="$DOMAINS/stoat/stoat.qcow2"
DISK_PATH_HOST="$DOMAINS_HOST/stoat/stoat.qcow2"
CLOUDINIT_DIR="$APPDATA/cloudinit"
CLOUDINIT_ISO="$APPDATA/cloudinit.iso"
CLOUDINIT_ISO_HOST="$APPDATA_HOST/cloudinit.iso"
FLAG_VM_CREATED="$APPDATA/.vm-created"

# ─── Helpers ──────────────────────────────────────────────────────────────────
log() { echo "[stoat-inabox] $*"; }

# ─── Setup dirs ───────────────────────────────────────────────────────────────
log "Starting up..."
log "Domain: $DOMAIN | VM: $VMNAME | CPUs: $VM_CPUS | RAM: ${VM_RAM}MB | Disk: ${VM_DISK}GB"
mkdir -p "$DOMAINS/stoat" "$APPDATA" "$CLOUDINIT_DIR"

# ─── Download base image ──────────────────────────────────────────────────────
if [ ! -f "$DISK_PATH" ]; then
    log "Downloading Ubuntu 22.04 cloud image..."
    curl -L --progress-bar "$UBUNTU_IMAGE_URL" -o "$DISK_PATH.tmp"
    mv "$DISK_PATH.tmp" "$DISK_PATH"
    log "Resizing disk to ${VM_DISK}GB..."
    qemu-img resize "$DISK_PATH" "${VM_DISK}G"
else
    log "Disk image already exists, skipping download."
fi

# ─── Generate cloud-init ──────────────────────────────────────────────────────
if [ ! -f "$FLAG_VM_CREATED" ]; then
    log "Generating cloud-init config..."

    # meta-data
    cat > "$CLOUDINIT_DIR/meta-data" <<EOF
instance-id: stoat-inabox
local-hostname: stoat
EOF

    # user-data — runs inside the VM on first boot
    cat > "$CLOUDINIT_DIR/user-data" <<EOF
#cloud-config
package_update: true
package_upgrade: true

# Create a user account so you can log into the VM if needed
users:
  - name: ubuntu
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    lock_passwd: false
    plain_text_passwd: 'stoat'

write_files:
  - path: /opt/stoat/compose.override.yml
    permissions: '0644'
    content: |
      services:
        database:
          image: mongo:4.4
          healthcheck:
            test: echo 'db.runCommand("ping").ok' | mongo localhost:27017/test --quiet
            interval: 10s
            timeout: 10s
            retries: 5
            start_period: 40s
        redis:
          image: eqalpha/keydb:x86_64_v6.3.0

packages:
  - ca-certificates
  - curl
  - git
  - micro
  - qemu-guest-agent

runcmd:
  # Enable and start QEMU guest agent (lets Unraid show the VM's IP)
  - systemctl enable qemu-guest-agent
  - systemctl start qemu-guest-agent

  # Install Docker
  - install -m 0755 -d /etc/apt/keyrings
  - curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  - chmod a+r /etc/apt/keyrings/docker.asc
  - echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu jammy stable" > /etc/apt/sources.list.d/docker.list
  - apt-get update
  - apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  # Clone Stoat self-hosted
  - git clone https://github.com/stoatchat/self-hosted /opt/stoat

  # Generate config
  - cd /opt/stoat && chmod +x ./generate_config.sh && ./generate_config.sh ${DOMAIN}


  # Start Stoat
  - cd /opt/stoat && docker compose up -d

  # Install systemd service so Stoat restarts on VM reboot
  - |
    cat > /etc/systemd/system/stoat.service << 'UNIT'
    [Unit]
    Description=Stoat Chat
    After=docker.service
    Requires=docker.service

    [Service]
    WorkingDirectory=/opt/stoat
    ExecStart=/usr/bin/docker compose up -d
    ExecStop=/usr/bin/docker compose down
    Restart=always
    RestartSec=10

    [Install]
    WantedBy=multi-user.target
    UNIT
  - systemctl enable stoat
  - systemctl daemon-reload

final_message: "Stoat is ready! Access it at https://${DOMAIN}"
EOF

    # Build cloud-init ISO
    log "Building cloud-init ISO..."
    cloud-localds "$CLOUDINIT_ISO" "$CLOUDINIT_DIR/user-data" "$CLOUDINIT_DIR/meta-data"
    log "Cloud-init ISO built at host path: $CLOUDINIT_ISO_HOST"
fi

# ─── Create and register VM ───────────────────────────────────────────────────
if [ ! -f "$FLAG_VM_CREATED" ]; then
    log "Checking for existing VM named '$VMNAME'..."
    if virsh --connect qemu:///system dominfo "$VMNAME" &>/dev/null; then
        log "VM already exists, skipping creation."
    else
        log "Creating VM '$VMNAME'..."

        virt-install \
            --connect qemu:///system \
            --name "$VMNAME" \
            --memory "$VM_RAM" \
            --vcpus "$VM_CPUS" \
            --disk path="$DISK_PATH_HOST",format=qcow2,bus=virtio \
            --disk path="$CLOUDINIT_ISO_HOST",device=cdrom \
            --os-variant ubuntu22.04 \
            --network bridge=br0,model=virtio \
            --graphics none \
            --console pty,target_type=serial \
            --noautoconsole \
            --import \
            --boot hd,cdrom

        log "VM '$VMNAME' created and started."
        log "First boot will take 5-10 minutes while Stoat installs inside the VM."
        log "Once done, Stoat will be accessible at https://$DOMAIN"
    fi

    touch "$FLAG_VM_CREATED"
else
    log "VM already set up, skipping creation."
fi

# ─── Monitoring loop ──────────────────────────────────────────────────────────
log "Entering monitoring loop (every ${CHECK_INTERVAL} minutes)..."
while true; do
    sleep $(( CHECK_INTERVAL * 60 ))
    VM_STATE=$(virsh --connect qemu:///system domstate "$VMNAME" 2>/dev/null || echo "unknown")
    log "VM '$VMNAME' state: $VM_STATE"
    if [ "$VM_STATE" != "running" ]; then
        log "VM is not running, starting it..."
        virsh --connect qemu:///system start "$VMNAME" || log "Failed to start VM — it may still be booting."
    fi
done