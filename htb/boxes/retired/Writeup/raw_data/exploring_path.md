# Exploring Path

* commands without full paths
jkr@writeup:~$ grep -r "^[a-zA-Z]" /etc/cron.d/ /etc/cron.daily/ 2>/dev/null | grep -v "^#" | head -20
/etc/cron.daily/apache2:set -e
/etc/cron.daily/apache2:set -u
/etc/cron.daily/apache2:type htcacheclean > /dev/null 2>&1 || exit 0
/etc/cron.daily/apache2:HTCACHECLEAN_MODE=daemon
/etc/cron.daily/apache2:HTCACHECLEAN_RUN=auto
/etc/cron.daily/apache2:HTCACHECLEAN_SIZE=300M
/etc/cron.daily/apache2:HTCACHECLEAN_PATH=/var/cache/apache2/mod_cache_disk
/etc/cron.daily/apache2:HTCACHECLEAN_OPTIONS=""
/etc/cron.daily/apache2:htcacheclean ${HTCACHECLEAN_OPTIONS}    \
/etc/cron.daily/bsdmainutils:if [ ! -x /usr/bin/cpp ]; then
/etc/cron.daily/bsdmainutils:fi
/etc/cron.daily/apt-compat:set -e
/etc/cron.daily/apt-compat:if [ -d /run/systemd/system ]; then
/etc/cron.daily/apt-compat:fi
/etc/cron.daily/apt-compat:check_power()
/etc/cron.daily/apt-compat:random_sleep()
/etc/cron.daily/apt-compat:random_sleep
/etc/cron.daily/apt-compat:check_power || exit 0
/etc/cron.daily/apt-compat:exec /usr/lib/apt/apt.systemd.daily
/etc/cron.daily/logrotate:test -x /usr/sbin/logrotate || exit 0

* what is root running

jkr@writeup:~$ ps aux | grep root
root         1  0.0  0.0   5932  1936 ?        Ss   05:30   0:00 init [2]
root         2  0.0  0.0      0     0 ?        S    05:30   0:00 [kthreadd]
root         3  0.0  0.0      0     0 ?        I<   05:30   0:00 [rcu_gp]
root         4  0.0  0.0      0     0 ?        I<   05:30   0:00 [rcu_par_gp]
root         5  0.0  0.0      0     0 ?        I<   05:30   0:00 [slub_flushwq]
root         6  0.0  0.0      0     0 ?        I<   05:30   0:00 [netns]
root         8  0.0  0.0      0     0 ?        I<   05:30   0:00 [kworker/0:0H-ev]
root        10  0.0  0.0      0     0 ?        I<   05:30   0:00 [mm_percpu_wq]
root        11  0.0  0.0      0     0 ?        I    05:30   0:00 [rcu_tasks_kthre]
root        12  0.0  0.0      0     0 ?        I    05:30   0:00 [rcu_tasks_rude_]
root        13  0.0  0.0      0     0 ?        I    05:30   0:00 [rcu_tasks_trace]
root        14  0.0  0.0      0     0 ?        S    05:30   0:00 [ksoftirqd/0]
root        15  0.0  0.0      0     0 ?        I    05:30   0:00 [rcu_preempt]
root         8  0.0  0.0      0     0 ?        I<   05:30   0:00 [kworker/0:0H-ev]
root        10  0.0  0.0      0     0 ?        I<   05:30   0:00 [mm_percpu_wq]
root        11  0.0  0.0      0     0 ?        I    05:30   0:00 [rcu_tasks_kthre]
root        12  0.0  0.0      0     0 ?        I    05:30   0:00 [rcu_tasks_rude_]
root        13  0.0  0.0      0     0 ?        I    05:30   0:00 [rcu_tasks_trace]
root        14  0.0  0.0      0     0 ?        S    05:30   0:00 [ksoftirqd/0]
root        15  0.0  0.0      0     0 ?        I    05:30   0:00 [rcu_preempt]
root        16  0.0  0.0      0     0 ?        S    05:30   0:00 [migration/0]
root        18  0.0  0.0      0     0 ?        S    05:30   0:00 [cpuhp/0]
root        20  0.0  0.0      0     0 ?        S    05:30   0:00 [kdevtmpfs]
root        21  0.0  0.0      0     0 ?        I<   05:30   0:00 [inet_frag_wq]
root        22  0.0  0.0      0     0 ?        S    05:30   0:00 [kauditd]
root        23  0.0  0.0      0     0 ?        S    05:30   0:00 [khungtaskd]
root        24  0.0  0.0      0     0 ?        S    05:30   0:00 [oom_reaper]
root        27  0.0  0.0      0     0 ?        I<   05:30   0:00 [writeback]
root        28  0.0  0.0      0     0 ?        S    05:30   0:00 [kcompactd0]
root        29  0.0  0.0      0     0 ?        SN   05:30   0:00 [ksmd]
root        30  0.0  0.0      0     0 ?        SN   05:30   0:00 [khugepaged]
root        31  0.0  0.0      0     0 ?        I<   05:30   0:00 [kintegrityd]
root        32  0.0  0.0      0     0 ?        I<   05:30   0:00 [kblockd]
root        33  0.0  0.0      0     0 ?        I<   05:30   0:00 [blkcg_punt_bio]
root        34  0.0  0.0      0     0 ?        I<   05:30   0:00 [tpm_dev_wq]
root        35  0.0  0.0      0     0 ?        I<   05:30   0:00 [edac-poller]
root        36  0.0  0.0      0     0 ?        I<   05:30   0:00 [devfreq_wq]
root        37  0.0  0.0      0     0 ?        I<   05:30   0:00 [kworker/0:1H-kb]
root        38  0.0  0.0      0     0 ?        S    05:30   0:00 [kswapd0]
root        44  0.0  0.0      0     0 ?        I<   05:30   0:00 [kthrotld]
root        46  0.0  0.0      0     0 ?        S    05:30   0:00 [irq/24-pciehp]
root        47  0.0  0.0      0     0 ?        S    05:30   0:00 [irq/25-pciehp]
root        48  0.0  0.0      0     0 ?        S    05:30   0:00 [irq/26-pciehp]
root        49  0.0  0.0      0     0 ?        S    05:30   0:00 [irq/27-pciehp]
root        50  0.0  0.0      0     0 ?        S    05:30   0:00 [irq/28-pciehp]
root        51  0.0  0.0      0     0 ?        S    05:30   0:00 [irq/29-pciehp]
root        52  0.0  0.0      0     0 ?        S    05:30   0:00 [irq/30-pciehp]
root        53  0.0  0.0      0     0 ?        S    05:30   0:00 [irq/31-pciehp]
root        54  0.0  0.0      0     0 ?        S    05:30   0:00 [irq/32-pciehp]
root        55  0.0  0.0      0     0 ?        S    05:30   0:00 [irq/33-pciehp]
root        56  0.0  0.0      0     0 ?        S    05:30   0:00 [irq/34-pciehp]
root        57  0.0  0.0      0     0 ?        S    05:30   0:00 [irq/35-pciehp]
root        58  0.0  0.0      0     0 ?        S    05:30   0:00 [irq/36-pciehp]
root        59  0.0  0.0      0     0 ?        S    05:30   0:00 [irq/37-pciehp]
root        60  0.0  0.0      0     0 ?        S    05:30   0:00 [irq/38-pciehp]
root        61  0.0  0.0      0     0 ?        S    05:30   0:00 [irq/39-pciehp]
root        62  0.0  0.0      0     0 ?        S    05:30   0:00 [irq/40-pciehp]
root        63  0.0  0.0      0     0 ?        S    05:30   0:00 [irq/41-pciehp]
root        64  0.0  0.0      0     0 ?        S    05:30   0:00 [irq/42-pciehp]
root        65  0.0  0.0      0     0 ?        S    05:30   0:00 [irq/43-pciehp]
root        66  0.0  0.0      0     0 ?        S    05:30   0:00 [irq/44-pciehp]
root        67  0.0  0.0      0     0 ?        S    05:30   0:00 [irq/45-pciehp]
root        68  0.0  0.0      0     0 ?        S    05:30   0:00 [irq/46-pciehp]
root        69  0.0  0.0      0     0 ?        S    05:30   0:00 [irq/47-pciehp]
root        70  0.0  0.0      0     0 ?        S    05:30   0:00 [irq/48-pciehp]
root        71  0.0  0.0      0     0 ?        S    05:30   0:00 [irq/49-pciehp]
root        72  0.0  0.0      0     0 ?        S    05:30   0:00 [irq/50-pciehp]
root        73  0.0  0.0      0     0 ?        S    05:30   0:00 [irq/51-pciehp]
root        74  0.0  0.0      0     0 ?        S    05:30   0:00 [irq/52-pciehp]
root        75  0.0  0.0      0     0 ?        S    05:30   0:00 [irq/53-pciehp]
root        76  0.0  0.0      0     0 ?        S    05:30   0:00 [irq/54-pciehp]
root        77  0.0  0.0      0     0 ?        S    05:30   0:00 [irq/55-pciehp]
root        78  0.0  0.0      0     0 ?        I<   05:30   0:00 [acpi_thermal_pm]
root        79  0.0  0.0      0     0 ?        I<   05:30   0:00 [mld]
root        80  0.0  0.0      0     0 ?        I<   05:30   0:00 [ipv6_addrconf]
root        85  0.0  0.0      0     0 ?        I<   05:30   0:00 [kstrp]
root        90  0.0  0.0      0     0 ?        I<   05:30   0:00 [zswap-shrink]
root        91  0.0  0.0      0     0 ?        I<   05:30   0:00 [kworker/u3:0]
root       142  0.0  0.0      0     0 ?        I    05:30   0:06 [kworker/0:2-eve]
root       145  0.0  0.0      0     0 ?        I<   05:30   0:00 [mpt_poll_0]
root       146  0.0  0.0      0     0 ?        I<   05:30   0:00 [mpt/0]
root       147  0.0  0.0      0     0 ?        I<   05:30   0:00 [ata_sff]
root       148  0.0  0.0      0     0 ?        S    05:30   0:00 [scsi_eh_0]
root       149  0.0  0.0      0     0 ?        I<   05:30   0:00 [scsi_tmf_0]
root       150  0.0  0.0      0     0 ?        S    05:30   0:00 [scsi_eh_1]
root       151  0.0  0.0      0     0 ?        I<   05:30   0:00 [scsi_tmf_1]
root       153  0.0  0.0      0     0 ?        S    05:30   0:00 [scsi_eh_2]
root       154  0.0  0.0      0     0 ?        I<   05:30   0:00 [scsi_tmf_2]
root       187  0.0  0.0      0     0 ?        S    05:30   0:00 [jbd2/sda1-8]
root       188  0.0  0.0      0     0 ?        I<   05:30   0:00 [ext4-rsv-conver]
root       393  0.0  0.2  22072  4348 ?        Ss   05:30   0:00 udevd --daemon
root       429  0.0  0.0      0     0 ?        S    05:30   0:00 [irq/59-vmw_vmci]
root       430  0.0  0.0      0     0 ?        S    05:30   0:00 [irq/60-vmw_vmci]
root       456  0.0  0.0      0     0 ?        I<   05:30   0:00 [cryptd]
root       516  0.0  0.0      0     0 ?        S    05:30   0:00 [irq/16-vmwgfx]
root      1270  0.0  0.1  14596  2776 ?        Ss   05:30   0:00 dhclient -4 -v -i -pf /run/dhclient.eth0.pid -lf /var/lib/dhcp/dhcli$nt.eth0.leases -I -df /var/lib/dhcp/dhclient6.eth0.leases eth0
root      1506  0.0  0.3 233748  6712 ?        Ssl  05:30   0:00 /usr/sbin/rsyslogd
root      1531  0.0  0.6 175600 12804 ?        Sl   05:30   0:09 /usr/bin/vmtoolsd
root      1573  0.0  1.5 306328 31100 ?        Ss   05:30   0:00 /usr/sbin/apache2 -k start
root      1654  0.0  0.1  10708  2420 ?        Ss   05:30   0:00 /usr/sbin/cron
root      1705  0.0  0.1  10388  2704 ?        S    05:30   0:00 /usr/sbin/elogind -D
root      1775  0.0  0.1   6016  3040 ?        S    05:30   0:00 /bin/bash /usr/bin/mysqld_safe
root      1838  0.0  0.9 427460 18236 ?        Sl   05:30   0:04 /usr/bin/python3 /usr/bin/fail2ban-server -s /var/run/fail2ban/fail2ban.sock -p /var/run/fail2ban/fail2ban.pid -b
root      1924  0.0  0.0   2484   936 ?        S    05:30   0:00 logger -t mysqld -p daemon error
root      1997  0.0  0.2  32296  4540 ?        Ss   05:30   0:00 sshd: /usr/sbin/sshd [listener] 0 of 10-100 startups
root      2086  0.0  0.0   5904  1812 tty1     Ss+  05:30   0:00 /sbin/getty 38400 tty1
root      2087  0.0  0.0   5904  1852 tty2     Ss+  05:30   0:00 /sbin/getty 38400 tty2
root      2088  0.0  0.0   5904  1812 tty3     Ss+  05:30   0:00 /sbin/getty 38400 tty3
root      2089  0.0  0.0   5904  1808 tty4     Ss+  05:30   0:00 /sbin/getty 38400 tty4
root      2090  0.0  0.0   5904  1956 tty5     Ss+  05:30   0:00 /sbin/getty 38400 tty5
root      2091  0.0  0.0   5904  1852 tty6     Ss+  05:30   0:00 /sbin/getty 38400 tty6
root      3378  0.0  0.0      0     0 ?        I    08:44   0:00 [kworker/u2:0-ev]
root      3497  0.0  0.5  66884 10584 ?        Ss   09:08   0:00 sshd: jkr [priv]
root      3720  0.0  0.0      0     0 ?        I    09:38   0:02 [kworker/0:0-eve]
root      3778  0.0  0.0      0     0 ?        I    09:48   0:00 [kworker/u2:2-ev]
jkr       4188  0.0  0.0   8208  1156 pts/0    S+   10:57   0:00 grep root


* possible scripts
jkr@writeup:~$ find /etc -name "*.sh" -readable -exec grep -l "staff\|/usr/local" {} \; 2>/dev/null
/etc/rcS.d/S13mountnfs.sh
/etc/init.d/mountnfs.sh

* run parts
-rwxr-xr-x 1 root root 19288 Apr  2  2017 /bin/run-parts
jkr@writeup:~$ file /bin/run-parts
/bin/run-parts: ELF 64-bit LSB shared object, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, for GNU/Linux 2.6.32, BuildID[sha1]=6b72c4eea85579fc7aca5b8e7c62fb97139a7529, stripped
jkr@writeup:~$

jkr@writeup:~$ uname -a
Linux writeup 6.1.0-13-amd64 #1 SMP PREEMPT_DYNAMIC Debian 6.1.55-1 (2023-09-29) x86_64 GNU/Linux
jkr@writeup:~$ groups
jkr cdrom floppy audio dip video plugdev staff netdev
jkr@writeup:~$ echo $PATH
/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games

* PATH HIJACKING STRATEGY - Overview

Per HTB box description: "user is found to be in a non-default group, which has 
write access to part of the PATH. A path hijacking results in escalation of 
privileges to root."

**Key Elements:**
- User jkr is in 'staff' group (non-default)
- /usr/local/bin and /usr/local/sbin are writable by staff
- PATH order: /usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
  → /usr/local/* comes FIRST
- Need to find a root process that executes a command without full path

**Investigated so far:**
1. Cron jobs - all use full paths or call binaries that are root-owned
2. mountnfs.sh - init script, runs at boot, not useful now
3. VMware tools (vmtoolsd) - running as root, SUID wrapper exists
4. /usr/bin/vmtoolsd --version fails with "could not obtain SBINDIR"

**Next steps to investigate:**
- Check /etc/network/if-up.d/ for scripts triggered by interface events
- Check if vmtoolsd spawns subprocesses without full paths
- Monitor root processes for unqualified command execution
- Test by placing common commands in /usr/local/bin and waiting for execution