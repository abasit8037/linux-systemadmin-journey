# SSH Hardening Checklist — Pre Go-Live

Use this before any server goes into production.  
Every box must be checked. No exceptions.

---

## Phase 1 — Before You Touch Anything

- [ ] Run `sshd -T` and document current values (your baseline)
- [ ] Check for override files: `ls /etc/ssh/sshd_config.d/`
- [ ] Confirm you have a working key pair before disabling passwords
- [ ] Ensure you have console/out-of-band access (if you lock yourself out)
- [ ] Backup current config: `sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak.$(date +%Y%m%d)`

---

## Phase 2 — Key Setup

- [ ] Generate Ed25519 key: `ssh-keygen -t ed25519 -C "description"`
- [ ] Set a passphrase (always)
- [ ] Deploy key: `ssh-copy-id -i ~/.ssh/key.pub user@server`
- [ ] Verify login with key **before** disabling passwords
- [ ] Set correct permissions: `chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys`

---

## Phase 3 — Harden sshd_config

- [ ] `PermitRootLogin no`
- [ ] `PasswordAuthentication no`
- [ ] `PubkeyAuthentication yes`
- [ ] `MaxAuthTries 3`
- [ ] `LoginGraceTime 20`
- [ ] `AllowUsers` set (whitelist)
- [ ] `X11Forwarding no`
- [ ] `AllowTcpForwarding no`
- [ ] `Port` changed from 22
- [ ] `Banner /etc/ssh/banner` configured
- [ ] Strong ciphers/MACs set

---

## Phase 4 — Validate Before Applying

- [ ] `sudo sshd -t` returns clean (no errors)
- [ ] Check override files again: `grep -r 'PasswordAuthentication' /etc/ssh/sshd_config.d/`
- [ ] Verify effective config: `sshd -T | grep passwordauthentication`

---

## Phase 5 — Apply Safely

- [ ] Open a NEW terminal session (do not close existing one)
- [ ] Test key login from new terminal: `ssh -i ~/.ssh/key -p PORT user@server`
- [ ] Only after confirmed: `sudo systemctl reload sshd` (not restart)
- [ ] Verify again: `sshd -T | grep -E 'permitrootlogin|passwordauthentication|port'`

---

## Phase 6 — Post-Hardening Audit

- [ ] Run `ssh-audit-commands.sh` — all PASS
- [ ] Check failed login attempts: `grep "Failed password" /var/log/auth.log | wc -l`
- [ ] Confirm your login still works
- [ ] Document changes made and date applied

---

## 🚨 Emergency Recovery

If you lock yourself out:
1. Use cloud console (AWS EC2 console, DigitalOcean console, etc.)
2. Mount disk and restore backup: `cp /etc/ssh/sshd_config.bak.DATE /etc/ssh/sshd_config`
3. Restart sshd from console: `systemctl restart sshd`

**This is why you always backup first and test in a new terminal.**
