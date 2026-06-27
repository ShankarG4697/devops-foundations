# Phase 1 — Learnings Log

---

## 1. Apache `ServerName` syntax error (inline comments)

**What happened:**
Apache threw an error rejecting `#` in ServerName line

**Why it happened (the actual mechanism):**
The directive parser treats `#` as a part of the value, not a comment delimiter because Apache does support `#` comments on their own line

The specific issue is that ServerName parses its entire remaining line as a single argument, so it never gets a chance to recognize `#` as a comment marker on that particular line.

**How I found it:**
(which command revealed the error — what did the output say?)
I found this issue by running `apachectl configtest`

**How I'd avoid it next time:**
Next time while setting up I need to put comments on their own line, not as inline

---

## 2. Docker Compose: `localhost` vs service name

**What happened:**
I tried to run API, Redis and RabbitMQ all under `localhost`. So got this error

**Why it happened (how does Docker Compose networking actually work?):**
In docker environment, each container has its own network space (`namespace`). So the `localhost` on each network will resolve on its own

**The fix:**
Use the `service name` (`redis`, `rabbitmq`) instead of `localhost`. Compose creates a shared network where Docker's internal DNS resolves each service name to that container's IP — `localhost` only ever points at the container's own loopback, never another container.

**General rule I'm taking away:**
(when do I use `localhost` vs a service name vs the host's real IP?)

- Use `localhost` in same process or same container
- Use `service name` in different container
- Use the `host IP` to reach Docker host itself

---

## 3. Multi-stage Dockerfile — builder vs runtime stage

**What does the builder stage do, in my own words:**
Installs `build-essential` because some Python packages need a compiler, then runs `pip install --user` to install dependencies into `/root/.local`.

**What does the runtime stage do, in my own words:**
Starts from a brand new, clean `python:3.11-slim` — it has no idea stage 1 ever existed

**Why `COPY --from=builder /root/.local /root/.local` works:**
It only copies `/root/.local` (Python packages), not `/usr/bin/gcc` or anything apt installed — those stay in the discarded stage 1

**What would break if I forgot `pip install --user`:**
If no `USER` directive is set, the package will be installed system wide `site-package directory` like

>/usr/local/lib/python3.11/site-packages/

**Why this matters (image size / attack surface):**
`single-stage` would keep that ~150-200MB layer permanently; `multi-stage` discards it; and a smaller image with no compiler means less to exploit if someone gets shell access

---

## 4. Stale Docker build cache producing wrong output

**What happened:**
The old cache layer served stale output. So even after source changed the changes were not reflected

**How I (we) diagnosed it wasn't a security issue:**
(what commands proved the PyPI package was clean?)
Downloaded the package fresh inside the container and read the actual file contents directly (via Python's `zipfile` module, since `unzip` wasn't installed) — confirmed the real PyPI release was modern, correct code, which meant the corruption was in the build process, not the source."

**The fix:**
When rebuilding need to use `docker build --no-cache`

**General rule I'm taking away:**
(when should I reach for `--no-cache`?)
When I see things not working as used to be, after dependency update or when debugging "locally works"

---

## 5. EC2 security group — HTTP rule missing

**What happened:**
The application was running but the `http` request gave timeout from the browser

**How I diagnosed it (what ruled out an Nginx config problem?):**
Since I was in `SSH` it is sure that instance was up and running, also when I `curl` from inside it worked and pointed to `firewall/SG`

**General rule I'm taking away:**
Always I need to check the `security group` inbounds before deep diving into application level

---

## 6. Quick reference — commands I used today that I want to remember

| Task | Command |
| --- | --- |
| Test Nginx config syntax | `sudo nginx -t` |
| Test Apache config syntax | `sudo apachectl configtest` |
| Reload Nginx | `sudo systemctl reload ngnix` |
| Reload Apache | `sudo systemctl reload apache2` |
| Check what's listening on a port | `ss -tlnp` or `lsof -i :80` |
| See running + stopped containers | `docker ps -a` |
| See logs for a crashed container | `docker logs <container-id>` |
| Force rebuild ignoring cache | `docker build --no-cache` |
| Check available RAM | `free -h` |
| Add swap space | `fallocate -l 1G /swapfile && mkswap /swapfile && swapon /swapfile` |

---

## 7. Open questions / things to look up later

- Why does `--user` in pip matter for multi-stage builds? (Answer Below)
- What's the difference between `restart: always` and `restart: unless-stopped`? (Answer Below)
- `swapfile` setup need to more digging for gaining confident when to use, where to use (Answer Below)

---

## Answers

## 1. Why does `--user` in pip matter for multi-stage builds?

Box 1 (stage 1, "builder"): has compilers, has pip, has internet access to download packages. This box gets thrown away completely once the build finishes — nothing from it survives unless you explicitly rescue something.

Box 2 (stage 2, "runtime"): starts empty (just a fresh Python install). This is the box that actually ships and runs.

> COPY --from=builder /root/.local /root/.local

This says: "reach into Box 1, grab this one specific folder, drop it into the same path in Box 2." That's it — that's the entire mechanism. Nothing else from Box 1 crosses over.

### So the real question is: where does pip put things, and does that location match what we're rescuing?

`pip install -r requirements.txt (no --user)` → installs to /`usr/local/lib/python3.11/site-packages/` — outside the folder the `COPY` line is rescuing

`pip install --user -r requirements.txt` → installs to `/root/.local/lib/python3.11/site-packages/` — inside the folder the `COPY` line is rescuing

`--user` doesn't do anything magical or Docker-specific. It's a completely ordinary pip flag that exists for a totally different reason in normal (non-Docker) use — letting a non-admin user install packages without sudo, into their own home folder. We're just repurposing that behavior here because it happens to put packages exactly where our `COPY` line is already looking.

---

## 2. What's the difference between `restart: always` and `restart: unless-stopped`?

- `always` — Docker restarts the container on failure and even if you manually `docker stop` it, the next daemon restart (e.g. host reboot) will bring it back up again.

- `unless-stopped` — restarts on failure or host reboot, but respects a manual stop — if you `docker stop`, it stays stopped even after a reboot, until you `docker start` it yourself.

---

## 3. Swap File

### When to use

When there is RAM constrain in the server but you application require more the need to use the `/swapfile`

### The general rule

swap is a safety net against OOM-kills on memory-constrained boxes, not a performance feature — disk-backed swap is orders of magnitude slower than RAM, so if you're relying on swap under normal load, that's a sign you need a bigger instance, not more swap.
