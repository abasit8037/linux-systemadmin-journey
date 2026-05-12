# 🐧 Linux SysAdmin Journey — Day 1
### Filesystem Hierarchy + Production Server Audit Script

![Day](https://img.shields.io/badge/Day-01%20of%2075-blue)
![OS](https://img.shields.io/badge/OS-Ubuntu%2022.04-orange)
![Status](https://img.shields.io/badge/Status-Active-brightgreen)

---

## 📌 Problem

Every time you SSH into a new server, you're flying blind.
Most people run `df -h` and `top` and call it a day.
That leaves critical things unchecked — open ports, failed logins,
inode exhaustion, recent config changes.

---

## ✅ Solution

A single Bash script (`server-audit.sh`) that gives you a complete
baseline of any Linux server in under 10 seconds — and saves it
to a timestamped report file.

---

## 🗂️ What I Learned Today

### Linux Filesystem Hierarchy (FHS) — The Mental Model

| Directory | Role | Why It Matters in Production |
|-----------|------|------------------------------|
| `/etc`    | Brain | All service configs live here. Change this = change behavior |
| `/var`    | Memory | Logs, queues, DB files. Grows over time. Monitor it |
| `/proc`   | Live pulse | Not a real disk — kernel exposes runtime data here |
| `/boot`   | Spine | Kernel + GRUB. If this fills up, server won't reboot |
| `/tmp`    | Whiteboard | Cleared on reboot. Never store persistent data here |
| `/dev`    | Everything-is-a-file | Disks, terminals, devices — all files in Linux |

### 💡 Key Insight — Inodes vs Disk Space

```bash
df -h   # shows disk space  ← everyone checks this
df -i   # shows inode usage ← almost nobody checks this
```

**Inodes are the filesystem's index.** You can have 200GB free
and STILL be unable to create new files if inodes are exhausted.
This is a real production failure mode. Always check both.

---

## 🛠️ Commands Used

```bash
# System identity
uname -a && hostnamectl && uptime -p

# Disk + inode usage
df -hT && df -i

# Find space consumers
du -sh /var/* | sort -rh | head -5

# Open listening ports
ss -tlnp

# Recent failed logins
grep "Failed password" /var/log/auth.log | tail -10

# Files changed in /etc last 24 hours
find /etc -mtime -1 -type f

# Full file metadata
stat /etc/passwd
```

---

## 📜 The Script

```bash
chmod +x server-audit.sh
sudo ./server-audit.sh
# Report saved to: /tmp/audit-<hostname>-<date>.txt
```

> Script file: [`server-audit.sh`](./server-audit.sh)

---

## 🔐 Security Angle

| What to check | Why |
|---------------|-----|
| `ss -tlnp` | Find unexpected open ports — sign of compromise |
| `grep "Failed password" /var/log/auth.log` | Brute force attempts |
| `find /etc -mtime -1` | Unauthorized config changes |
| `last -n 10` | Who logged in and when |

---

## 🧠 Problems I Hit

**Problem:** Script couldn't read `/var/log/auth.log`
**Error:** Permission denied
**Fix:** Run with `sudo` — auth logs are root-readable only
**Lesson:** Always think about privilege level before scripting

---

## 🚀 Next Improvement Ideas

- [ ] Add email alert if disk usage > 80%
- [ ] Add cron job to run this every Sunday automatically  
- [ ] Export report as JSON for log aggregation pipelines
- [ ] Compare two audit reports to detect changes (diff mode)

---

## 📅 Series

This is Day 1 of a 75-day public Linux SysAdmin journey.

| Day | Topic |
|-----|-------|
| ✅ Day 01 | Filesystem Hierarchy + Server Audit Script |
| ⏳ Day 02 | User & Group Management |
| ⏳ Day 03 | File Permissions + ACLs |
| ... | ... |

Follow the journey on https://www.linkedin.com/in/abdul-basit-34abb722a/· Star this repo to track progress

---

*Learning in public. Corrections welcome.*
