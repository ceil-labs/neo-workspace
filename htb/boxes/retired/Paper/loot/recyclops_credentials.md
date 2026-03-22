# Recyclops Bot - Credentials & Findings

## Date: 2026-03-21

## Credentials Found

### RocketChat Bot Credentials
**Source:** /home/dwight/hubot/.env
```
ROCKETCHAT_URL='http://127.0.0.1:48320'
ROCKETCHAT_USER=recyclops
ROCKETCHAT_PASSWORD=Queenofblad3s!23
ROCKETCHAT_USESSL=false
RESPOND_TO_DM=true
RESPOND_TO_EDITED=true
PORT=8000
BIND_ADDRESS=127.0.0.1
```

### Potential System Credentials
- **Username:** dwight (bot runs as this user)
- **Password:** Queenofblad3s!23 (likely reused)

## Files Accessed
- /home/dwight/hubot/.env ✅
- /home/dwight/bot_restart.sh ✅
- /home/dwight/hubot/.hubot_history ✅
- /home/dwight/.esd_auth ✅

## Access Denied
- /home/dwight/user.txt ❌ (r-------- permissions, only dwight can read)

## Next Steps
1. SSH as dwight@10.129.136.31 with password Queenofblad3s!23
2. If successful, read user.txt
3. Continue enumeration for privilege escalation
