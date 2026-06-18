# GoCD agent permission denied on /godata
## Source: Docs/Trouble-shooting/GoCD agent permission denied on godata.md

## Troubleshooting the Badminton Court GoCD agent startup

### Symptom
GoCD agent containers crash-loop with the error:
```
$ cp -rfv /go-agent/config/agent-bootstrapper-logback-include.xml /go-working-dir/config/agent-bootstrapper-logback-include.xml
cp: can't create '/go-working-dir/config/agent-bootstrapper-logback-include.xml': Permission denied
/docker-entrypoint.sh: cannot cp -rfv /go-agent/config/agent-bootstrapper-logback-include.xml /go-working-dir/config/agent-bootstrapper-logback-include.xml
```

The agent restarts repeatedly and never registers with the server.

### Root Cause
The official GoCD agent entrypoint (`/docker-entrypoint.sh`) tries to copy a logback config file into `/go-working-dir/config/` — which is a symlink to `/godata/config/`. The copy fails because:

1. **A bind mount created `/godata/config/` as root-owned** — when Docker mounts a single file into a path (e.g., `./.env.docker:/godata/config/.env.common:ro`), it auto-creates the parent directory `/godata/config/` as `root:root` with mode `755`. The `go` user (UID 1000) cannot write to it.

2. **`/godata/config/` doesn't exist on first run** — the base image creates `/godata` (owned by `go:root`) but NOT the `config/` subdirectory. The official entrypoint expects this subdir to exist but doesn't `mkdir` it.

3. **Wrong chown target** — `chown -R go:go /godata` fails because there's no `go` group in `/etc/group` (the `go` user has GID 0, which is `root`).

### Diagnostic Steps

1. **Inspect the agent container's mounts:**
   ```bash
   docker inspect gocd-agent-1 --format '{{range .Mounts}}{{.Source}} -> {{.Destination}}{{println}}{{end}}'
   ```
   If you see `./.env.docker -> /godata/config/.env.common`, that mount is creating `/godata/config/` as root-owned.

2. **Check ownership of `/godata` inside the container:**
   ```bash
   docker run --rm -it --entrypoint sh gocd-server-gocd-agent-1 -c "ls -la /godata/ && stat /godata"
   ```
   Expected: `drwxrwxr-x 2 go root ... /godata` (owned by go:root, mode 775)

3. **Check if `go` user/group exist:**
   ```bash
   docker run --rm -it --entrypoint sh gocd-server-gocd-agent-1 -c "
     grep '^go:' /etc/passwd
     grep '^go:' /etc/group
     stat -c '%U:%G  uid=%u gid=%g' /godata
     gosu go id
   "
   ```
   If `chown go:go` fails with "unknown user/group", the `go` group doesn't exist (the user `go` has GID 0 = root group).

4. **Verify the fix works in a fresh container (no mounts):**
   ```bash
   docker run --rm -it --entrypoint sh gocd-server-gocd-agent-1 -c "
     gosu go mkdir -p /godata/config
     gosu go touch /godata/config/test
     gosu go cp /go-agent/config/agent-bootstrapper-logback-include.xml /godata/config/
     echo 'All operations succeeded'
   "
   ```
   If this succeeds, the issue is the bind mount, not the image.

### Fix

#### Step 1: Remove the bind mount that creates root-owned dirs

In `gocd-server/docker-compose.yml`, remove this line from ALL agent definitions:

```yaml
# Remove this line from every gocd-agent-N service:
- ./.env.docker:/godata/config/.env.common:ro
```

This mount is redundant — the agents already have `env_file: .env.docker` which injects all env vars directly. The file mount was creating `/godata/config/` as root-owned.

#### Step 2: Add `/godata` directory creation to `agent-entrypoint.sh`

Edit `gocd-server/Scripts/agent-entrypoint.sh` and add this block right before `exec gosu go /docker-entrypoint.sh "$@"`:

```sh
# --- FIX /godata OWNERSHIP ---
# /godata is already owned by go:root (uid 1000, gid 0) in the base image.
# The issue is that /godata/config doesn't exist on first run. Create the
# subdirs AS the go user so they're owned correctly, and pre-copy the
# logback config so the official entrypoint's cp is a no-op.
echo "Preparing /godata subdirectories as go user..."
gosu go mkdir -p /godata/config /godata/logs /godata/pipelines

# Pre-copy the logback config as go user (the file the official entrypoint tries to cp)
if [ -f /go-agent/config/agent-bootstrapper-logback-include.xml ]; then
    echo "Pre-copying logback config as go user..."
    gosu go cp -f /go-agent/config/agent-bootstrapper-logback-include.xml /godata/config/agent-bootstrapper-logback-include.xml
fi
```

#### Step 3: Rebuild and force-recreate the agents

```bash
cd gocd-server
docker compose --env-file .env.docker build
docker compose --env-file .env.docker up -d --force-recreate
```

### Why `gosu go mkdir` Works

- `gosu go` runs the command as UID 1000 (the `go` user)
- `/godata` is owned by `go:root` with mode `775` (owner has write)
- So `go` can create subdirectories inside `/godata`
- The subdirs inherit `go:root` ownership
- The subsequent `gosu go cp` can write to `/godata/config/`

### Why `chown -R go:go /godata` Fails

The base image's `/etc/passwd` has:
```
go:x:1000:0::/home/go:/bin/bash   ← GID is 0 (root group)
```

And `/etc/group` has:
```
root:x:0:root,go                   ← go is a member of root group, no 'go' group exists
```

So `chown go:go` fails because there's no `go` group. Use `chown -R 1000:0 /godata` (numeric UIDs) if you need to chown.

### Verification

After the fix, agent logs should show:
```
Preparing /godata subdirectories as go user...
Pre-copying logback config as go user...
Starting GoCD agent as user 'go'...
/docker-entrypoint.sh: Creating directories and symlinks...
$ cp -rfv /go-agent/config/agent-bootstrapper-logback-include.xml /go-working-dir/config/agent-bootstrapper-logback-include.xml
'/go-agent/config/agent-bootstrapper-logback-include.xml' -> '/go-working-dir/config/agent-bootstrapper-logback-include.xml'
```

No "Permission denied" error. The agent then registers with the server and shows as `Idle` in the GoCD UI.

### Related Files
- `gocd-server/docker-compose.yml` — remove the `.env.common` bind mount
- `gocd-server/Scripts/agent-entrypoint.sh` — add `/godata` directory creation
- `gocd-server/Dockerfile.agent` — base image (no changes needed)
