#!/bin/bash
FN=$0
NC='\033[0m'
cyan='\e[0;36m'
blue='\033[0;34m'
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[1;33m'
bold=`tput bold`
normal=`tput sgr0`

echo -e $cyan'
█▒░  █▒▒█▄███▒▒█▄▄██▒░░▒▄▄▄▄▄▄
█▒▒░░░█▒░█░░░░░▒█░░░░█░░█▀░░░░█
███████░ █▄▄▄▄░░█░░░░█░░█ ▀░░░█
██▒░ ▒█░ █░░░░░░█▄▄█░░░░█░░▀░░█
█▒░░ ██░ █▄▄▄█░░█░░ ▒█  ▒▄▄▄▀▄█
█░░  ▒░  ▒░ ░▒ ░▒░  ░▒  ▒▒▒░░░▒
▒░  ▒░  ░  ░  ░    ░  ▒░░░  ░
░    ░          ░      ░░    ░
░[CLOUDFLARE RESOLVER v1]░
Created for RAID.NOTHING'$NC
usage() {
  echo_warn 'Usage...'
  echo "${FN} <hostname>"
}
echo_error() {
  echo -e ${red}$1${NC};
}
echo_message() {
  echo -e ${blue}$1${NC};
}
echo_ok() {
  echo -e ${green}$1${NC};
}
echo_warn() {
  echo -e ${yellow}$1${NC};
}
if [ $# -eq 0 ]; then
    usage
    exit 1
fi
if [[ $EUID -ne 0 ]]; then
  echo_error "Must be ran as root!" 2>&1
  exit 1
fi
command -v nmap >/dev/null 2>&1 || {
  echo_error >&2 'Nmap is not installed!';
  exit 1;
}
NMAP=`which nmap`
HOST=$1

echo_message "[+] Grabbing IP of host ${1}"
HOST_IPS=`dig +short ${1}`
echo_message "[+] Found the following IPs (Assuming cloudflare)"
echo "  - ${HOST_IPS
[*]}"
echo_message "[+] Brute forcing DNS"
DNS=`$NMAP --script dns-brute -sn ${1} | grep -oE ".*${1} - .*" | sed -r "s/^\|_? *//" | sed "s/ - /-/"`
NONCLOUDFLARE=()
for ENTRY in $DNS;
do
  echo_ok "  - ${ENTRY}"
  CF=0
  for IP in $HOST_IPS;
  do
    line=$(echo ${ENTRY} | grep -o $IP)
    if [ $? -eq 0 ]; then
      CF=1;
    fi
  done
  if [ $CF -eq 1 ]; then
    echo_warn " -- cloudflare"
  else
    ENTRY_IP=$(echo ${ENTRY} | sed "s/.*-//")
    IPV6=""
    IPV6_CHECK=$(echo $ENTRY_IP | grep -o :)
    if [ -z "${IPV6_CHECK}" ]; then
      IPV6="1"
    fi
    if [[ " ${NONCLOUDFLARE
[*]} " == *"${ENTRY_IP}"* ]]; then
        echo_ok " -- ${bold}Not CF${normal}";
    else
      if [ -z "${IPV6}" ]; then
        echo_warn " -- Detected IPv6 ADDR attempting to convert to IPv4"
        IFS=':' read -ra IPV6_SEGMENT <<< "$ENTRY_IP"
        ENTRY_IP=$(( `printf "%d" 0x${IPV6_SEGMENT[6]}` >> 8 )).$(( `printf "%d" 0x${IPV6_SEGMENT[6]}` & 0xff )).$(( `printf "%d" 0x${IPV6_SEGMENT[7]}` >> 8 )).$(( `printf "%d" 0x${IPV6_SEGMENT[7]}` & 0xff ))
        echo_ok " -- Found IP ${ENTRY_IP}";
      fi
      line=$($NMAP -sV -sS -F $ENTRY_IP | grep -o cloudflare)
      if [ -z "${line}" ]; then
        echo_ok " -- ${bold}Not CF${normal}";
        NONCLOUDFLARE+=("${ENTRY_IP}")
      else
        echo_warn " -- cloudflare"
      fi
    fi
  fi
done

echo_message "[+] List of non cloudflare IPs from ${1}..."
echo ${NONCLOUDFLARE
[*]}
   
