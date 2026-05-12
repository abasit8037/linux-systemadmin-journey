#!/bin/bash
# ============================================
# server-audit.sh
# Production Server Baseline Audit
# Author: Your Name
# Usage: sudo ./server-audit.sh
# ============================================

REPORT="/tmp/audit-$(hostname)-$(date +%F).txt"

echo "========================================" | tee $REPORT
echo "  SERVER AUDIT — $(date)"               | tee -a $REPORT
echo "  Host: $(hostname)"                     | tee -a $REPORT
echo "========================================" | tee -a $REPORT

echo -e "\n[1] SYSTEM INFO" | tee -a $REPORT
uname -a | tee -a $REPORT
uptime | tee -a $REPORT

echo -e "\n[2] DISK USAGE (Space)" | tee -a $REPORT
df -hT | grep -v 'tmpfs' | grep -Ev '/dev/sdb1|efivarfs' | tee -a $REPORT

echo -e "\n[3] DISK USAGE (Inodes)" | tee -a $REPORT
df -i | grep -v 'tmpfs' | grep -Ev '/dev/sdb1|efivarfs'| tee -a $REPORT

echo -e "\n[4] TOP SPACE CONSUMERS in /var" | tee -a $REPORT
du -sh /var/* 2>/dev/null | sort -rh | head -5 | tee -a $REPORT

echo -e "\n[5] OPEN LISTENING PORTS" | tee -a $REPORT
ss -tlnp | tee -a $REPORT

echo -e "\n[6] LAST 5 FAILED LOGIN ATTEMPTS" | tee -a $REPORT
grep "Failed password" /var/log/auth.log 2>/dev/null | tail -5 | tee -a $REPORT

echo -e "\n[7] /etc FILES CHANGED IN LAST 24 HOURS" | tee -a $REPORT
find /etc -mtime -1 -type f 2>/dev/null | tee -a $REPORT

echo -e "\n[8] LAST 5 LOGINS" | tee -a $REPORT
last -n 5 | tee -a $REPORT

echo -e "\n[9] CURRENTLY LOGGED IN USERS" | tee -a $REPORT
w | tee -a $REPORT

echo -e "\n[10] TOP 5 CPU PROCESSES" | tee -a $REPORT
ps -eo pid,user,%cpu,%mem,comm --sort=-%cpu | column -t | head

echo -e "\n[10] TOP 5 MEM PROCESSES" | tee -a $REPORT
ps -eo pid,user,%cpu,%mem,comm:30 --sort=-%mem | head

echo -e "\n========================================" | tee -a $REPORT
echo "  Report saved: $REPORT"
echo "========================================"
