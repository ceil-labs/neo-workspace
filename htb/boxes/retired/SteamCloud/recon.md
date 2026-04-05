# SteamCloud - Reconnaissance

## Target
- **IP:** 10.129.96.167
- **OS:** Linux (minikube / Debian 10)
- **Difficulty:** Easy
- **Platform:** Hack The Box

## Nmap Scan
```bash
nmap -sC -sV -Pn 10.129.96.167
```

**Results:**
| Port | Service | Version | Notes |
|------|---------|---------|-------|
| 22/tcp | ssh | OpenSSH 7.9p1 Debian 10+deb10u2 | |
| 8443/tcp | ssl/https | Golang kube-apiserver (minikube) | Kubernetes API server |
| 10250/tcp | ssl/kubelet | kubelet API | 🔴 **Unauthenticated access** |

### SSL Cert Intelligence
- **CN:** minikube / system:masters
- **SANs:** minikubeCA, kubernetes.default.svc.cluster.local, kubernetes
- **Node name:** steamcloud

## Kubernetes Cluster Enumeration

### Port 8443 — kube-apiserver
- Requires authentication (token or cert)
- Version: v1.22.3 (from `/version` endpoint)
- Anonymous access returns HTTP 403
- Health endpoint `/healthz` returns `ok` without auth

### Port 10250 — kubelet API (🔴 Key Attack Surface)
- **No authentication required** — critical misconfiguration
- Exposes all pods/containers on the node
- Supports exec, run, logs, and containerLogs endpoints

**Endpoints tested:**
| Endpoint | Purpose | Result |
|----------|---------|--------|
| `GET /pods` | List all pods | ✅ Returns full pod list |
| `GET /logs/` | Host logs | ✅ Accessible |
| `GET /containerLogs/{ns}/{pod}/{container}` | Container logs | ✅ Accessible |
| `POST /run/{ns}/{pod}/{container}` | Execute command | ✅ Works |

### Discovered Pods (from `/pods`)
| Pod | Namespace | Container Image | Volume Mounts |
|-----|-----------|----------------|---------------|
| nginx | default | nginx:1.14.2 | `/opt/flag` (hostPath) → `/root` |
| kube-apiserver-steamcloud | kube-system | k8s.gcr.io/kube-apiserver:v1.22.3 | — |
| kube-controller-manager-steamcloud | kube-system | k8s.gcr.io/kube-controller-manager:v1.22.3 | — |
| kube-scheduler-steamcloud | kube-system | k8s.gcr.io/kube-scheduler:v1.22.3 | — |
| etcd-steamcloud | kube-system | k8s.gcr.io/etcd:3.5.0-0 | — |
| kube-proxy-* | kube-system | k8s.gcr.io/kube-proxy:v1.22.3 | — |
| coredns-* | kube-system | k8s.gcr.io/coredns/coredns:v1.8.4 | — |
| storage-provisioner | kube-system | gcr.io/k8s-minikube/storage-provisioner:v5 | `/tmp` (hostPath) |

### Key Observation — Existing Misconfiguration
The pre-existing `nginx` pod in `default` namespace already had a hostPath volume:
```
volumes:
- name: flag
  hostPath:
    path: /opt/flag
volumeMounts:
- name: flag
  mountPath: /root
```
This mounts `/opt/flag` from the host into the container at `/root` — likely containing `user.txt`.

## Initial Observations

1. **Minikube cluster** running inside the HTB VM — not a real multi-node cluster
2. **Kubelet API wide open** — unauthenticated access to `/run` endpoint allows arbitrary command execution in any pod
3. The `default` service account token is mounted into every pod at `/var/run/secrets/kubernetes.io/serviceaccount/`
4. This token can authenticate to the kube-apiserver and create new pods

## Next Steps
- [x] Execute commands via kubelet `/run` endpoint → read user.txt
- [x] Extract service account token → kube-apiserver authentication
- [x] Create malicious pod with hostPath `/` volume → container escape
- [x] Read root.txt from escaped container

## Lessons
- **Kubelet authentication:** By default, kubelet on port 10250 requires authentication (cert or token). An open kubelet API is a critical finding.
- **minikube gotcha:** minikube runs a single-node cluster inside a VM — the "host" from a container's perspective is the minikube node, not the physical HTB machine.
- **hostPath volumes:** Mounting host directories (especially `/`) into containers is dangerous — it allows container → host escape.
