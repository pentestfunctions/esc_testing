#!/bin/bash

# Define color variables
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "\n${BLUE}System Date:${NC}"
date

# Header for checking tools and system information
echo -e "\n${BLUE}Checking available tools and system information...${NC}"

# Define a list of commonly used tools
tools=(nmap aws grep ps crontab tmux xclip xsel df nc ncat lsblk lscpu lpstat uname netcat nc.traditional wget curl ping gcc g++ make gdb base64 socat python python2 python3 perl php ruby xterm doas sudo fetch docker lxc ctr runc rkt kubectl)

# Initialize strings for available and unavailable tools
available_tools=""
unavailable_tools=""

# Check each tool and add to the appropriate string
for tool in "${tools[@]}"; do
    if command -v "$tool" >/dev/null 2>&1; then
        available_tools+="${GREEN}$tool${NC} "
    else
        unavailable_tools+="${RED}$tool${NC} "
    fi
done

# Print out the lists of available and unavailable tools
echo -e "Available tools: $available_tools"
echo -e "Unavailable tools: $unavailable_tools"

echo -e "\n${YELLOW}Checking for authenticator processes...${NC}"
# Capture the output of grep, excluding lines containing grep itself
auth_processes=$(ps -ef | grep "authenticator" | grep -v grep)

# Check if the output is empty
if [ -z "$auth_processes" ]; then
    echo -e "${RED}No authenticator processes found.${NC}"
else
    echo "$auth_processes"
fi

echo -e "\n${YELLOW}Checking tmux sessions...${NC}"
tmux_processes=$(tmux ls 2>/dev/null)
# Check if the output is empty
if [ -z "$tmux_processes" ]; then
    echo -e "${RED}No TMUX processes found.${NC}"
else
    echo "$tmux_processes"
fi

# Check clipboard tools
if command -v xclip >/dev/null 2>&1; then
    echo -e "\n${GREEN}Clipboard contents using xclip:${NC}"
    xclip -o -selection clipboard
    xclip -o
elif command -v xsel >/dev/null 2>&1; then
    echo -e "\n${GREEN}Clipboard contents using xsel:${NC}"
    xsel -ob
    xsel -o
else
    echo -e "\n${RED}Clipboard tools not found.${NC}"
fi

echo -e "\n${BLUE}Filesystem information:${NC}"
df -h || lsblk

echo -e "\n${BLUE}CPU information:${NC}"
lscpu

echo -e "\n${BLUE}Available printers:${NC}"
prints_found=$(lpstat -a 2>/dev/null)
# Check if the output is empty
if [ -z "$prints_found" ]; then
    echo -e "${RED}No printers processes found.${NC}"
else
    echo "$prints_found"
fi

echo -e "\n${BLUE}System Information:${NC}"
echo "-------------------"
(cat /proc/version || uname -a) 2>/dev/null | sed 's/^/''Kernel Version: '"$NC"'/'

echo -e "\n${BLUE}Distribution Information:${NC}"
echo "-------------------------"
lsb_release -a 2>/dev/null | sed 's/^/''LSB Release: ''/'
cat /etc/os-release 2>/dev/null | grep -E '^(PRETTY_NAME|NAME|VERSION_ID)' | sed 's/^/''OS Release: ''/'

echo -e "\n${BLUE}Crontab entries:${NC}"
crontab -l 2>/dev/null

echo -e "\n${BLUE}System-wide crontab and scheduled tasks:${NC}"
cat /etc/crontab /etc/cron* /etc/at* /etc/anacrontab /var/spool/cron/crontabs/root 2>/dev/null | grep -v "^#"

echo -e "\n${YELLOW}Checking for SUID files...${NC}"
# List of known GTFO bins
gtfobins_list=("aa-exec" "ab" "agetty" "alpine" "ar" "arj" "arp" "as" "ascii-xfr" "ash" "aspell" "atobm" "awk" "base32" "base64" "basenc" "basez" "bash" "bc" "bridge" "busybox" "bzip2" "cabal" "capsh" "cat" "chmod" "choom" "chown" "chroot" "clamscan" "cmp" "column" "comm" "cp" "cpio" "cpulimit" "csh" "csplit" "csvtool" "cupsfilter" "curl" "cut" "dash" "date" "dd" "debugfs" "dialog" "diff" "dig" "distcc" "dmsetup" "docker" "dosbox" "ed" "efax" "elvish" "emacs" "env" "eqn" "espeak" "expand" "expect" "file" "find" "fish" "flock" "fmt" "fold" "gawk" "gcore" "gdb" "genie" "genisoimage" "gimp" "grep" "gtester" "gzip" "hd" "head" "hexdump" "highlight" "hping3" "iconv" "install" "ionice" "ip" "ispell" "jjs" "join" "jq" "jrunscript" "julia" "ksh" "ksshell" "kubectl" "ld.so" "less" "logsave" "look" "lua" "make" "mawk" "more" "mosquitto" "msgattrib" "msgcat" "msgconv" "msgfilter" "msgmerge" "msguniq" "multitime" "mv" "nasm" "nawk" "ncftp" "nft" "nice" "nl" "nm" "nmap" "node" "nohup" "od" "openssl" "openvpn" "pandoc" "paste" "perf" "perl" "pexec" "pg" "php" "pidstat" "pr" "ptx" "python" "rc" "readelf" "restic" "rev" "rlwrap" "rsync" "rtorrent" "run-parts" "rview" "rvim" "sash" "scanmem" "sed" "setarch" "setfacl" "setlock" "shuf" "soelim" "softlimit" "sort" "sqlite3" "ss" "ssh-agent" "ssh-keygen" "ssh-keyscan" "sshpass" "start-stop-daemon" "stdbuf" "strace" "strings" "sysctl" "systemctl" "tac" "tail" "taskset" "tbl" "tclsh" "tee" "terraform" "tftp" "tic" "time" "timeout" "troff" "ul" "unexpand" "uniq" "unshare" "unsquashfs" "unzip" "update-alternatives" "uudecode" "uuencode" "vagrant" "view" "vigr" "vim" "vimdiff" "vipw" "w3m" "watch" "wc" "wget" "whiptail" "xargs" "xdotool" "xmodmap" "xmore" "xxd" "xz" "yash" "zsh" "zsoelim")
# Check if any SUID binaries exist that match the list
found_flag=0
find /usr -perm -u=s -type f 2>/dev/null -exec basename {} \; | while read -r binary; do
    if printf '%s\n' "${gtfobins_list[@]}" | grep -q -w "$binary"; then
        echo "Vulnerable SUID binary found: $binary"
        found_flag=1
    fi
done
if [ $found_flag -eq 0 ]; then
    echo "No known SUID Priv Esc Found"
fi

echo -e "\n${YELLOW}Getting capabilities${NC}"
getcap -r / 2>/dev/null

echo -e "\n${YELLOW}Current path:${NC}"
echo $PATH

echo -e "\n${YELLOW}Checking for SGID files...${NC}"
find / -perm -2000 -type f 2>/dev/null

echo -e "\n${YELLOW}Checking for files with no owner${NC}"
find / -nouser -ls 2>/dev/null

echo -e "\n${YELLOW}Checking for passwords in config files${NC}"
find / -type f -name \"*.conf\" -exec grep -i password {} \; -print 2>/dev/null

echo -e "\n${YELLOW}Checking for writeable configuration files${NC}"
find /etc/ -writable -type f 2>/dev/null

((uname -r | grep "\-grsec" >/dev/null 2>&1 || grep "grsecurity" /etc/sysctl.conf >/dev/null 2>&1) && echo "Yes" || echo "Not found grsecurity")
(which paxctl-ng paxctl >/dev/null 2>&1 && echo "Yes" || echo "Not found PaX")
(grep "exec-shield" /etc/sysctl.conf || echo "Not found Execshield")
(sestatus 2>/dev/null || echo "Not found sestatus")
grep -E "(user|username|login|pass|password|pw|credentials)[=:]" /etc/fstab /etc/mtab 2>/dev/null
cat /etc/fstab 2>/dev/null | grep -v "^#" | grep -Pv "\W*\#" 2>/dev/null
ls /dev 2>/dev/null | grep -i "sd"
cat /proc/sys/kernel/randomize_va_space 2>/dev/null # If 0, not enabled
sudo -V | grep "Sudo ver" | grep "1\.[01234567]\.[0-9]\+\|1\.8\.1[0-9]\*\|1\.8\.2[01234567]"
