# 🔐 Linux Server Hardening

> Production-level SSH hardening guide built from real lab work.  
> Not a tutorial — a working reference used on actual servers.

---

## 📌 What This Is

This repo documents how I harden Linux servers before they go anywhere near production.

It started with SSH — the front door to every server. Default config is a liability.  
This is how you lock it down correctly, verify it actually worked, and detect when something's wrong.

**Built on:** Ubuntu 22.04 LTS / tested on RHEL-based systems  
**Skill level:** Junior-to-mid SysAdmin  
**Focus:** Security-first, production-ready, automatable

---

## 📁 Repository Structure

```
linux-server-hardening/
├── README.md
├── ssh/
│   ├── sshd_config.hardened        # Hardened SSH config (production template)
│   ├── ssh-hardening-checklist.md  # Step-by-step checklist before go-live
│   └── ssh-audit-commands.sh       # Audit script — PASS/FAIL per setting
└── scripts/
    └── (automation scripts — added as project grows)
```

---

## ⚡ Quick Start

### 1. Audit your current SSH state FIRST
```bash
sshd -T | grep -E 'permitrootlogin|passwordauthentication|pubkeyauthentication|port|maxauthtries|logingracetime'
```
Know your baseline before touching anything.

### 2. Run the audit script
```bash
chmod +x ssh/ssh-audit-commands.sh
sudo bash ssh/ssh-audit-commands.sh
```
Each setting outputs PASS or FAIL. Fix every FAIL before going live.

### 3. Apply hardened config
```bash
# Backup first — always
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak.$(date +%Y%m%d)

# Apply hardened config
sudo cp ssh/sshd_config.hardened /etc/ssh/sshd_config

# Validate — never skip this
sudo sshd -t
```

### 4. Test key login in a NEW terminal before reloading
```bash
ssh -i ~/.ssh/your_key -p 2222 user@server
```
Only reload AFTER you confirm key login works. This is how you avoid lockouts.

```bash
sudo systemctl reload sshd   # reload = no dropped sessions
```

---

## 🔒 What Gets Hardened & Why

| Setting | Value | Why |
|---|---|---|
| `PermitRootLogin` | `no` | Root login = no audit trail of who did what |
| `PasswordAuthentication` | `no` | Passwords are brute-forceable. Keys are not. |
| `PubkeyAuthentication` | `yes` | Enforce key-based auth only |
| `MaxAuthTries` | `3` | Limit brute-force attempts per connection |
| `LoginGraceTime` | `20` | Close unauthenticated connections fast |
| `AllowUsers` | `deploy ops` | Whitelist only. Unknown users can't attempt auth |
| `Port` | `2222` | Non-default port reduces automated bot noise |
| `X11Forwarding` | `no` | Attack surface. Disable unless explicitly needed |
| `AllowTcpForwarding` | `no` | Prevents SSH tunnel abuse |
| `Protocol` | `2` | Protocol 1 is broken. Never use it. |
| `KexAlgorithms` | `curve25519-sha256` | Modern key exchange only |
| `Ciphers` | `chacha20-poly1305, aes256-gcm` | Strong ciphers only |
| `MACs` | `hmac-sha2-512-etm` | Strong MAC algorithms only |

---

## ⚠️ The Override File Trap

**This catches most people.**

Setting `PasswordAuthentication no` in `/etc/ssh/sshd_config` is NOT enough.

Many distros (Ubuntu cloud images especially) ship override files in:
```
/etc/ssh/sshd_config.d/
```

These **silently override** your main config.

**Always verify what SSH is ACTUALLY running:**
```bash
sshd -T | grep passwordauthentication
```

Don't trust what you wrote. Trust what's running.

```bash
# Check for override files
ls -la /etc/ssh/sshd_config.d/
grep -r "PasswordAuthentication" /etc/ssh/sshd_config.d/
```

---

## 🔑 Key Generation

**Use Ed25519. Not RSA 2048.**

```bash
# Generate Ed25519 key pair
ssh-keygen -t ed25519 -C "server-name-$(date +%Y%m%d)" -f ~/.ssh/server_ed25519

# Deploy to server
ssh-copy-id -i ~/.ssh/server_ed25519.pub user@server

# Manual method (same result)
cat ~/.ssh/server_ed25519.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
chmod 700 ~/.ssh/
```

**Why Ed25519 over RSA 2048:**
- Shorter keys, stronger security
- Faster signature verification
- Resistant to side-channel attacks
- RSA 1024 is broken. RSA 2048 is marginal. Ed25519 is current standard.

---

## 🚨 Attack Detection

Run these on any live server. The numbers will surprise you.

```bash
# How many failed password attempts total
grep "Failed password" /var/log/auth.log | wc -l

# Top attacking IPs
grep "Failed password" /var/log/auth.log \
  | awk '{print $11}' | sort | uniq -c | sort -rn | head -20

# Username enumeration attempts
grep "Invalid user" /var/log/auth.log | head -20

# Successful key logins (your baseline)
grep "Accepted publickey" /var/log/auth.log

# Watch live
tail -f /var/log/auth.log | grep sshd
```

---

## 🔍 Multi-Developer Key Management

**Deploying 3 developer keys to one server without overwriting:**
```bash
# Each key goes on its own line in authorized_keys
cat dev1_key.pub >> ~/.ssh/authorized_keys
cat dev2_key.pub >> ~/.ssh/authorized_keys
cat dev3_key.pub >> ~/.ssh/authorized_keys
```

**Revoking one developer without affecting others:**
```bash
# Find their key fingerprint first
ssh-keygen -lf dev1_key.pub

# Remove only their line from authorized_keys
grep -v "dev1_identifier" ~/.ssh/authorized_keys > /tmp/ak_tmp
mv /tmp/ak_tmp ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

---

## 🔐 Security Checklist Before Go-Live

- [ ] Root login disabled
- [ ] Password auth disabled
- [ ] Key-based auth confirmed working
- [ ] Override files in `sshd_config.d/` checked
- [ ] `sshd -T` output verified (not just sshd_config)
- [ ] `sshd -t` passed clean
- [ ] New terminal key login tested before reload
- [ ] `systemctl reload` used (not restart)
- [ ] Audit script run — all PASS
- [ ] Banner configured
- [ ] AllowUsers set (not default open)
- [ ] fail2ban configured (or equivalent)

---

## 🧰 Tools Used

| Tool | Purpose |
|---|---|
| `sshd -T` | Show effective running SSH config |
| `sshd -t` | Validate config syntax before applying |
| `ssh-keygen` | Generate key pairs |
| `ssh-copy-id` | Deploy public keys |
| `systemctl reload sshd` | Apply changes without dropping sessions |
| `journalctl` | View systemd logs |
| `tail -f /var/log/auth.log` | Monitor live auth events |

---

## 📈 Project Status

| Component | Status |
|---|---|
| SSH Hardening | ✅ Complete |
| Audit Script | ✅ Complete |
| User & Permission Hardening | 🔄 In Progress |
| fail2ban Configuration |  Planned |
| Firewall (UFW/iptables) |  Planned |
| Automated Backup System |  Planned |
| Monitoring Setup |  Planned  |

---

## 👤 Author

**Basit** — Junior SysAdmin | Linux | Security-first infrastructure  
Building in public. Every file in this repo came from real lab work.

---

> ⭐ If this helped you, star the repo.  
> Found an error or a better approach? Open an issue.
