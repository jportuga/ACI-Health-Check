#!/bin/bash

STATE='/state'

if [ -e $STATE ]
	then
		date +"%m.%d.%Y %T "
		echo "$STATE file exists. Doing nothing."
		exit 1
	else
		echo "+++++++++++++++++++++++++++++++++++++++++++"
		echo "++++++++++++ OVF Config script ++++++++++++"
		echo "+ System will be rebooted after execution +"
		echo "+++++++++++++++++++++++++++++++++++++++++++"


		# create XML file with settings
		vmtoolsd --cmd "info-get guestinfo.ovfenv" > /tmp/ovf_env.xml
		TMPXML='/tmp/ovf_env.xml'

		# gathering values
		HOSTNAME=`cat $TMPXML| grep -e hostname |sed -n -e '/value\=/ s/.*\=\" *//p'|sed 's/\"\/>//'`
		echo "Hostname	$HOSTNAME"
		IP=`cat $TMPXML| grep -e ip_address |sed -n -e '/value\=/ s/.*\=\" *//p'|sed 's/\"\/>//'`
		echo "IP		$IP"
		NETMASK=`cat $TMPXML| grep -e netmask |sed -n -e '/value\=/ s/.*\=\" *//p'|sed 's/\"\/>//'`
		echo "Netmask		$NETMASK"
		GW=`cat $TMPXML| grep -e default_gateway |sed -n -e '/value\=/ s/.*\=\" *//p'|sed 's/\"\/>//'`
		echo "Gateway		$GW"
		DNS0=`cat $TMPXML| grep -e dns |sed -n -e '/value\=/ s/.*\=\" *//p'|sed 's/\"\/>//'`
		echo "DNS		$DNS0"
		PREFIX=`/bin/ipcalc -p $IP $NETMASK | awk -F "=" '{print $2}'`

		# fetch existing netwrok interface device name
		IFACE=`networkctl | grep "  2"| awk '{print $2}'`
		echo "Interface	$IFACE"

		# If you don't want DHCP, let's convert into static
		rm /etc/systemd/network/99-dhcp-en.network
		cat << XXX > /etc/systemd/network/99-static-en.network
[Match]
Name=$IFACE
[Network]
Address=$IP/$PREFIX
Gateway=$GW
DNS=$DNS0
XXX

		# Set Hostname
		echo "Setting Hostname..."
		hostnamectl set-hostname $HOSTNAME --static

		# Notification for future
		echo "This script will not be executed on next boot if $STATE file exists"
		echo "If you want to execute this configuration on next boot remove $STATE file"

		echo "Creating State file"
		date > /state

		# Wait a bit and reboot
		sleep 5
		reboot
fi
