#!/bin/bash

# exit if no local dnsmasq found
DNSMASQ_RESOLV_CONF=/var/run/dnsmasq/resolv.conf
test -f ${DNSMASQ_RESOLV_CONF} || exit 0

# we need to be root to manipulate VPN DNS configuration
if [[ ${EUID} -ne 0 ]]; then
  echo "Please run this as user root (with sudo) to enforce using local dnsmasq as first nameserver"
  exit 0
fi

# on VPN startup
if [[ ${EVENT} = "up" && ${MODE} = "ncsvc" ]]; then
  # set primary nameserver to local dnsmasq service
  SEARCH=$(grep "^search" /etc/resolv.conf)
  echo -e "${SEARCH} tomtomgroup.com\nnameserver 127.0.0.1\nnameserver ${DNS1}\nnameserver ${DNS2}" > /etc/resolv.conf

  # backup current upstream nameservers used by dnsmasq
  cp ${DNSMASQ_RESOLV_CONF} ${DNSMASQ_RESOLV_CONF}.vpn

  # configure dnsmasq to use upstream nameservers as provided by VPN
  echo -e "nameserver ${DNS1}\nnameserver ${DNS2}" > ${DNSMASQ_RESOLV_CONF}
fi

# on VPN shutdown
if [[ ${EVENT} = "down" && ${MODE} = "ncsvc" ]]; then
  # restore upstream nameservers
  mv ${DNSMASQ_RESOLV_CONF}.vpn ${DNSMASQ_RESOLV_CONF}
fi
