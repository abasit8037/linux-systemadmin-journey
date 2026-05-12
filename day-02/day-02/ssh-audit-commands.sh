#!/bin/bash
# ============================================================
# ssh-audit-commands.sh
# SSH Security Audit Script — PASS/FAIL per setting
# Usage: sudo bash ssh-audit-commands.sh
# Exit code 1 if any setting fails (CI/CD compatible)
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PASS=0
FAIL=0

print_pass() { echo -e "${GREEN}[PASS]${NC} $1"; ((PASS++)); }
print_fail() { echo -e "${RED}[FAIL]${NC} $1"; ((FAIL++)); }
print_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_header() { echo -e "\n${YELLOW}=== $1 ===${NC}"; }

# Must run as root
if [[ $EUID -ne 0 ]]; then
  echo -e "${RED}[ERROR]${NC} Run as root: sudo bash ssh-audit-commands.sh"
  exit 1
fi

echo "============================================"
echo " SSH Security Audit — $(hostname) — $(date)"
echo "============================================"

# --- Core Auth Settings ---
print_header "Authentication"

val=$(sshd -T 2>/dev/null | grep "^permitrootlogin" | awk '{print $2}')
[[ "$val" == "no" ]] && print_pass "PermitRootLogin = no" || print_fail "PermitRootLogin = $val (expected: no)"

val=$(sshd -T 2>/dev/null | grep "^passwordauthentication" | awk '{print $2}')
[[ "$val" == "no" ]] && print_pass "PasswordAuthentication = no" || print_fail "PasswordAuthentication = $val (expected: no)"

val=$(sshd -T 2>/dev/null | grep "^pubkeyauthentication" | awk '{print $2}')
[[ "$val" == "yes" ]] && print_pass "PubkeyAuthentication = yes" || print_fail "PubkeyAuthentication = $val (expected: yes)"

val=$(sshd -T 2>/dev/null | grep "^permitemptypasswords" | awk '{print $2}')
[[ "$val" == "no" ]] && print_pass "PermitEmptyPasswords = no" || print_fail "PermitEmptyPasswords = $val (expected: no)"

# --- Limits ---
print_header "Connection Limits"

val=$(sshd -T 2>/dev/null | grep "^maxauthtries" | awk '{print $2}')
[[ "$val" -le 3 ]] 2>/dev/null && print_pass "MaxAuthTries = $val (<=3)" || print_fail "MaxAuthTries = $val (expected: <=3)"

val=$(sshd -T 2>/dev/null | grep "^logingracetime" | awk '{print $2}')
[[ "$val" -le 30 ]] 2>/dev/null && print_pass "LoginGraceTime = $val seconds (<=30)" || print_fail "LoginGraceTime = $val (expected: <=30)"

# --- Port ---
print_header "Port"

val=$(sshd -T 2>/dev/null | grep "^port" | awk '{print $2}')
[[ "$val" != "22" ]] && print_pass "Port = $val (non-default)" || print_warn "Port = 22 (default, consider changing)"

# --- Forwarding ---
print_header "Forwarding & Display"

val=$(sshd -T 2>/dev/null | grep "^x11forwarding" | awk '{print $2}')
[[ "$val" == "no" ]] && print_pass "X11Forwarding = no" || print_fail "X11Forwarding = $val (expected: no)"

val=$(sshd -T 2>/dev/null | grep "^allowtcpforwarding" | awk '{print $2}')
[[ "$val" == "no" ]] && print_pass "AllowTcpForwarding = no" || print_fail "AllowTcpForwarding = $val (expected: no)"

# --- Override File Check ---
print_header "Override File Check"

if ls /etc/ssh/sshd_config.d/*.conf 2>/dev/null | grep -q .; then
  print_warn "Override files found in /etc/ssh/sshd_config.d/ — check these manually:"
  ls /etc/ssh/sshd_config.d/
  echo "  Run: grep -r 'PasswordAuthentication\|PermitRootLogin' /etc/ssh/sshd_config.d/"
else
  print_pass "No override files in /etc/ssh/sshd_config.d/"
fi

# --- AllowUsers Check ---
print_header "Access Control"

val=$(sshd -T 2>/dev/null | grep "^allowusers" | awk '{print $2}')
if [[ -n "$val" ]]; then
  print_pass "AllowUsers is set: $val"
else
  print_fail "AllowUsers not set — all users can attempt login"
fi

# --- SSH Key Audit ---
print_header "Authorized Keys Audit"

echo "Scanning for authorized_keys files..."
find /home /root -name "authorized_keys" 2>/dev/null | while read f; do
  count=$(wc -l < "$f")
  echo "  Found: $f ($count key(s))"
done

# --- Summary ---
echo ""
echo "============================================"
echo " RESULTS: ${GREEN}${PASS} PASSED${NC} | ${RED}${FAIL} FAILED${NC}"
echo "============================================"

if [[ $FAIL -gt 0 ]]; then
  echo -e "${RED}Action required: Fix $FAIL failing setting(s) before production.${NC}"
  exit 1
else
  echo -e "${GREEN}All checks passed. Server meets SSH hardening baseline.${NC}"
  exit 0
fi
