#!/bin/bash
set -e

echo "🔐 Generating ephemeral SSH key..."
ssh-keygen -t rsa -b 4096 -f /flatcar/id_rsa -N ""

PUB_KEY=$(cat /flatcar/id_rsa.pub)

echo "📝 Creating Butane config..."

cat > /flatcar/config.bu <<EOF
variant: flatcar
version: 1.0.0

passwd:
  users:
    - name: core
      ssh_authorized_keys:
        - ${PUB_KEY}
EOF

echo "🔄 Converting Butane → Ignition..."
butane /flatcar/config.bu -o /flatcar/config.ign

echo "🚀 Starting Flatcar VM..."

qemu-system-x86_64 \
  -m 2048 \
  -smp 2 \
  -machine type=q35,accel=tcg \
  -drive file=flatcar.img,if=virtio \
  -boot c \
  -netdev user,id=net0,hostfwd=tcp::2222-:22 \
  -device virtio-net-pci,netdev=net0 \
  -fw_cfg name=opt/com.coreos/config,file=config.ign \
  -nographic > vm.log 2>&1 &

VM_PID=$!

echo "⏳ Waiting for SSH..."
for i in {1..60}; do
if ssh -i id_rsa \
    -o StrictHostKeyChecking=no \
    -o ConnectTimeout=2 \
    -o BatchMode=yes \
    -p 2222 core@localhost "echo ready" >/dev/null 2>&1; then
    echo "✅ SSH is fully ready"
    exit 0
fi
echo "⏳ Waiting for SSH..."
sleep 2
done
echo "❌ SSH failed to become ready"
exit 1

echo "🔍 Running Trivy scan remotely..."

ssh -i /flatcar/id_rsa -p 2222 core@localhost <<'EOF'
set -e
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh
sudo ./bin/trivy rootfs / \
  --scanners vuln,misconfig \
  -f sarif \
  -o /tmp/report.sarif
EOF

echo "📥 Copying report from VM..."
scp -i /flatcar/id_rsa -P 2222 \
    -o StrictHostKeyChecking=no \
    core@localhost:/tmp/report.sarif \
    /flatcar/report.sarif

echo "📄 Report saved to /flatcar/report.sarif"

echo "🛑 Shutting down VM..."
kill $VM_PID
wait $VM_PID