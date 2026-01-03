# React App Deployment with Ansible

Automated deployment of React application using:
- **Docker Private Registry** (with authentication)
- **Kubernetes** (single master node)
- **HAProxy** (load balancer with SSL support)

---

## 📋 Table of Contents

- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Deployment](#deployment)
- [Management](#management)
- [Troubleshooting](#troubleshooting)
- [SSL/HTTPS Setup](#sslhttps-setup)

---

## 🏗️ Architecture
```
User Request (HTTP/HTTPS)
    ↓
HAProxy Load Balancer (Port 80/443)
    ↓
Kubernetes Service (NodePort 30080)
    ↓
3x React App Pods (Replicas)
    ↓
Nginx (serving static files)
    ↑
Docker Private Registry (Port 5000)
- Username/Password Authentication
- Stores application images
```

---

## ✅ Prerequisites

### System Requirements
- **OS**: Ubuntu 24.04 LTS
- **RAM**: Minimum 4GB (8GB recommended)
- **CPU**: Minimum 2 cores (4 cores recommended)
- **Disk**: 20GB free space
- **Network**: Static IP address

### Software Requirements
- Ansible 2.14+
- Python 3.10+
- SSH access to target server

---

## 🚀 Quick Start

### 1. Clone/Download Project
```bash
cd ~
# Assume project is in ~/ansible-deployment
```

### 2. Configure IP Address and Settings

Edit inventory file:
```bash
nano inventories/production/hosts.yml
```

Replace IP address:
```yaml
all:
  children:
    k8s_cluster:
      hosts:
        k8s-master:
          ansible_host: YOUR_SERVER_IP  # ← Change this
          ansible_connection: local
          ansible_python_interpreter: /usr/bin/python3
```

Edit variables:
```bash
nano inventories/production/group_vars/all.yml
```

Update these values:
```yaml
---
# General Configuration
domain_name: myreactapp.duckdns.org       # Change if you have domain
email_address: your-email@gmail.com        # ← Change this
server_ip: YOUR_SERVER_IP                  # ← Change this

# Docker Registry Configuration
registry_port: 5000
registry_username: admin                   # ← Change if needed
registry_password: SecurePassword123!      # ← Change this (IMPORTANT!)
registry_base_path: /opt/docker-registry

# Application Configuration
app_name: trial-deployment                 # ← Change app name
app_replicas: 3                            # Number of pods
app_source_path: /home/USER/my-app/trial-deployment  # ← Change path
app_nodeport: 30080

# HAProxy Configuration
haproxy_stats_port: 8404
haproxy_stats_username: admin              # ← Change if needed
haproxy_stats_password: password123        # ← Change this

# Kubernetes Configuration
k8s_pod_cidr: 10.244.0.0/16
k8s_version: "1.28"
```

### 3. Update Hardcoded Values

Update these files with your username/IP:

**File: `roles/kubernetes/tasks/main.yml`**
```bash
# Find and replace "docker-server" with your username
sed -i 's/docker-server/YOUR_USERNAME/g' roles/kubernetes/tasks/main.yml
```

**File: `roles/react-app/tasks/main.yml`**
```bash
sed -i 's/docker-server/YOUR_USERNAME/g' roles/react-app/tasks/main.yml
```

**File: `roles/kubernetes/files/containerd-config.toml`**
```bash
# Replace IP and credentials
nano roles/kubernetes/files/containerd-config.toml

# Update these lines:
[plugins."io.containerd.grpc.v1.cri".registry.mirrors."YOUR_IP:5000"]
  endpoint = ["http://YOUR_IP:5000"]

[plugins."io.containerd.grpc.v1.cri".registry.configs."YOUR_IP:5000".auth]
  username = "YOUR_USERNAME"
  password = "YOUR_PASSWORD"
```

**File: `roles/docker-registry/files/daemon.json`**
```bash
nano roles/docker-registry/files/daemon.json

# Update:
{
  "insecure-registries": ["YOUR_IP:5000"]
}
```

**File: `roles/react-app/files/k8s-deployment.yml`**
```bash
nano roles/react-app/files/k8s-deployment.yml

# Update image line:
image: YOUR_IP:5000/YOUR_APP_NAME:latest
```

**File: `roles/haproxy/files/haproxy.cfg`**
```bash
nano roles/haproxy/files/haproxy.cfg

# Update backend server:
server k8s-master YOUR_IP:30080 check
```

**File: `roles/haproxy/files/renew-cert.sh`** (if using SSL)
```bash
nano roles/haproxy/files/renew-cert.sh

# Update domain:
cat /etc/letsencrypt/live/YOUR_DOMAIN/fullchain.pem ...
```

### 4. Install Dependencies
```bash
make install
```

Or manually:
```bash
ansible-galaxy collection install -r requirements.yml
sudo apt install -y python3-kubernetes python3-docker
```

### 5. Test Connection
```bash
ansible all -m ping
```

Expected output:
```
k8s-master | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

### 6. Deploy
```bash
# Deploy everything
make deploy

# Or deploy individually
make deploy-registry   # Docker registry
make deploy-k8s        # Kubernetes
make deploy-app        # React application
make deploy-haproxy    # HAProxy
```

---

## ⚙️ Configuration

### Change IP Address (Template)

Create a script to replace all IPs:
```bash
cat > scripts/change-ip.sh << 'SCRIPT'
#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: ./change-ip.sh NEW_IP"
    exit 1
fi

NEW_IP=$1
OLD_IP="192.168.95.135"

echo "Replacing $OLD_IP with $NEW_IP..."

# Inventory
sed -i "s/$OLD_IP/$NEW_IP/g" inventories/production/hosts.yml
sed -i "s/$OLD_IP/$NEW_IP/g" inventories/production/group_vars/all.yml

# Kubernetes files
sed -i "s/$OLD_IP/$NEW_IP/g" roles/kubernetes/files/containerd-config.toml

# Docker registry files
sed -i "s/$OLD_IP/$NEW_IP/g" roles/docker-registry/files/daemon.json

# React app files
sed -i "s/$OLD_IP/$NEW_IP/g" roles/react-app/files/k8s-deployment.yml

# HAProxy files
sed -i "s/$OLD_IP/$NEW_IP/g" roles/haproxy/files/haproxy.cfg

echo "Done! IP changed from $OLD_IP to $NEW_IP"
echo "Please review files before deploying."
SCRIPT

chmod +x scripts/change-ip.sh
```

Usage:
```bash
./scripts/change-ip.sh 192.168.1.100
```

### Change Username (Template)
```bash
cat > scripts/change-username.sh << 'SCRIPT'
#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: ./change-username.sh NEW_USERNAME"
    exit 1
fi

NEW_USER=$1
OLD_USER="docker-server"

echo "Replacing $OLD_USER with $NEW_USER..."

# Kubernetes tasks
sed -i "s/$OLD_USER/$NEW_USER/g" roles/kubernetes/tasks/main.yml

# React app tasks
sed -i "s/$OLD_USER/$NEW_USER/g" roles/react-app/tasks/main.yml

# Group vars
sed -i "s/\/home\/$OLD_USER/\/home\/$NEW_USER/g" inventories/production/group_vars/all.yml

echo "Done! Username changed from $OLD_USER to $NEW_USER"
SCRIPT

chmod +x scripts/change-username.sh
```

Usage:
```bash
./scripts/change-username.sh myuser
```

---

## 🎯 Deployment

### Full Deployment
```bash
ansible-playbook playbooks/site.yml
```

### Individual Components
```bash
# Docker Private Registry
ansible-playbook playbooks/deploy-registry.yml

# Kubernetes Cluster
ansible-playbook playbooks/deploy-kubernetes.yml

# React Application
ansible-playbook playbooks/deploy-app.yml

# HAProxy Load Balancer
ansible-playbook playbooks/deploy-haproxy.yml
```

### Dry Run (Check Mode)
```bash
ansible-playbook playbooks/site.yml --check --diff
```

---

## 🔧 Management

### Update Application
```bash
# Edit source code
cd ~/my-app/trial-deployment
# Make changes...

# Rebuild and redeploy
ansible-playbook playbooks/deploy-app.yml
```

### Scale Application
```bash
# Edit group_vars
nano inventories/production/group_vars/all.yml
# Change app_replicas: 5

# Or directly with kubectl
kubectl scale deployment trial-deployment --replicas=5
```

### View Logs
```bash
# Application logs
kubectl logs -l app=trial-deployment --tail=100

# HAProxy logs
sudo tail -f /var/log/haproxy.log

# Registry logs
docker logs docker-registry
```

### Check Status
```bash
# All components
kubectl get all
docker ps
sudo systemctl status haproxy

# Specific component
kubectl get pods -o wide
kubectl describe deployment trial-deployment
```

### Access Registry
```bash
# Login
docker login 192.168.95.135:5000
# Username: admin
# Password: SecurePassword123!

# List images
curl -u admin:SecurePassword123! http://192.168.95.135:5000/v2/_catalog

# Pull image
docker pull 192.168.95.135:5000/trial-deployment:latest
```

---

## �� Troubleshooting

### Registry Not Accessible
```bash
# Check if running
docker ps | grep registry

# Restart
cd /opt/docker-registry
docker-compose restart

# Check logs
docker logs docker-registry
```

### Kubernetes Pods Not Starting
```bash
# Check pods
kubectl get pods
kubectl describe pod POD_NAME

# Check events
kubectl get events --sort-by='.lastTimestamp'

# Check node
kubectl get nodes
kubectl describe node NODE_NAME
```

### HAProxy Not Working
```bash
# Check status
sudo systemctl status haproxy

# Test config
sudo haproxy -c -f /etc/haproxy/haproxy.cfg

# Restart
sudo systemctl restart haproxy

# Check logs
sudo journalctl -u haproxy -f
```

### Image Pull Errors
```bash
# Check if secret exists
kubectl get secret regcred

# Recreate secret
kubectl delete secret regcred
ansible-playbook playbooks/deploy-app.yml
```

### Network Issues
```bash
# Check containerd registry config
sudo cat /etc/containerd/config.toml | grep -A 10 registry

# Restart containerd
sudo systemctl restart containerd

# Check Docker daemon
sudo cat /etc/docker/daemon.json
sudo systemctl restart docker
```

---

## 🔐 SSL/HTTPS Setup

### Prerequisites

1. **Get a Domain**
   - Free: DuckDNS (duckdns.org), Freenom
   - Paid: Namecheap, Cloudflare

2. **Point DNS to Your Server**
```
   A Record: yourdomain.com → YOUR_SERVER_IP
```

3. **Open Firewall Ports**
```bash
   sudo ufw allow 80/tcp
   sudo ufw allow 443/tcp
```

### Enable SSL

1. **Update Configuration**
```bash
nano inventories/production/group_vars/all.yml
```
```yaml
domain_name: yourdomain.duckdns.org
email_address: your-real-email@gmail.com
```

2. **Uncomment SSL Tasks**
```bash
nano roles/haproxy/tasks/main.yml
```

Uncomment all lines in "UNCOMMENT SECTION BELOW WHEN YOU HAVE A DOMAIN"

3. **Uncomment SSL Config**
```bash
nano roles/haproxy/files/haproxy.cfg
```

Uncomment HTTPS frontend section and HTTP redirect

4. **Deploy**
```bash
ansible-playbook playbooks/deploy-haproxy.yml
```

### Certificate Auto-Renewal

Certificate automatically renews via cron job:
```bash
# Check cron job
sudo crontab -l

# Manual renewal
sudo /usr/local/bin/renew-haproxy-cert.sh
```

---

## 📊 Access URLs

| Service | URL | Credentials |
|---------|-----|-------------|
| **Application** | `http://YOUR_IP` | - |
| **HAProxy Stats** | `http://YOUR_IP:8404/stats` | admin / password123 |
| **Registry API** | `http://YOUR_IP:5000/v2/_catalog` | admin / SecurePassword123! |
| **Kubernetes API** | `https://YOUR_IP:6443` | Via kubeconfig |

---

## 📁 Project Structure
```
ansible-deployment/
├── ansible.cfg                          # Ansible configuration
├── Makefile                             # Helper commands
├── requirements.yml                     # Ansible collections
├── README.md                           # This file
├── inventories/
│   └── production/
│       ├── hosts.yml                   # Inventory file
│       └── group_vars/
│           └── all.yml                 # Variables
├── playbooks/
│   ├── site.yml                        # Main playbook
│   ├── deploy-registry.yml            # Registry playbook
│   ├── deploy-kubernetes.yml          # K8s playbook
│   ├── deploy-app.yml                 # App playbook
│   └── deploy-haproxy.yml             # HAProxy playbook
└── roles/
    ├── common/                         # Common tasks
    ├── docker-registry/               # Private registry
    ├── kubernetes/                    # K8s cluster
    ├── react-app/                     # Application
    └── haproxy/                       # Load balancer
```

---

## 🔄 CI/CD Integration

### Manual Deployment
```bash
# Update code
cd ~/my-app/trial-deployment
git pull origin main

# Deploy
ansible-playbook playbooks/deploy-app.yml
```

### Automated with Git Hooks
```bash
# Create post-receive hook
cat > ~/my-app/trial-deployment/.git/hooks/post-receive << 'HOOK'
#!/bin/bash
cd ~/ansible-deployment
ansible-playbook playbooks/deploy-app.yml
HOOK

chmod +x ~/my-app/trial-deployment/.git/hooks/post-receive
```

---

## 🛡️ Security Best Practices

### Change Default Passwords
```bash
# Registry password
nano inventories/production/group_vars/all.yml
# Update registry_password

# HAProxy stats password
nano roles/haproxy/files/haproxy.cfg
# Update stats auth line

# Redeploy
make deploy
```

### Firewall Configuration
```bash
# Allow only necessary ports
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp        # SSH
sudo ufw allow 80/tcp        # HTTP
sudo ufw allow 443/tcp       # HTTPS (if using SSL)
sudo ufw allow 6443/tcp      # Kubernetes API (if needed)
sudo ufw enable
```

### Regular Updates
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Update Docker images
docker pull registry:2
cd /opt/docker-registry
docker-compose up -d

# Update Kubernetes
# Follow official upgrade guide
```

---

## 📞 Support

### Useful Commands
```bash
# Check all services
make check

# View all pods
kubectl get pods -A

# View all containers
docker ps -a

# Clean up
make clean
```

### Common Issues

1. **"Address already in use"**
   - Check: `sudo netstat -tulpn | grep :80`
   - Fix: Stop conflicting service

2. **"Permission denied"**
   - Check: User in docker group
   - Fix: `sudo usermod -aG docker $USER`

3. **"Image pull failed"**
   - Check: Registry accessible
   - Fix: Verify credentials and network

---

## 📝 License

MIT License - Feel free to modify and use

---

## 🙏 Acknowledgments

- Ansible Community
- Kubernetes Documentation
- HAProxy Documentation
- Docker Registry Documentation

---

**Last Updated**: January 2026
**Version**: 1.0.0
