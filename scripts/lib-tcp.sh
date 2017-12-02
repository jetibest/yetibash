#!/bin/bash
#source=https://github.com/jetibest/yetibash/scripts/lib-tcp.sh

_TCP_FD=""
_TCP_TIMEOUT_READLINE="1"
tcp-help()
{
	echo "WARNING: Not fully implemented yet."
	echo ""
}
tcp-fd()
{
	if [[ "$1" =~ ^[0-9]+$ ]]
	then
		_TCP_FD="$1"
	else
		echo "$_TCP_FD"
	fi
}
tcp-connect()
{
	# Interpret parameters
	local hostname="$1"
	local port="$2"
	basc-read -p "Remote hostname: " -m DOMAIN_NAME -i "$1" hostname
	basc-read -p "Remote port: " -m NUMERIC -i "$2" port
	
	# Create a new filedescriptor and set this one as current fd
	local fd=0
	while [ -e /proc/$$/fd/$fd ]
	do
		fd=$((fd + 1))
	done
	tcp-fd "$fd"
	
	# Actually create the connection
	local tcp_path="/dev/tcp/$hostname/$port"
	
	eval "exec $_TCP_FD<>'$tcp_path'"
}
tcp-readline()
{
	# Usage:
	# echo "$(tcp-readline)"
	# echo "$(tcp-readline ln && echo -en "$ln")"
	# tcp-readline -u "custom filedescriptor"
	# tcp-readline -t "timeout in s (may use decimals for ms)"
	if [[ "$1" == "-u" ]]
	then
		if [[ "$2" =~ ^[0-9]+$ ]]
		then
			_TCP_FD="$2"
		else
			echo "error: bad value for filedescriptor: $2"
		fi
		shift 2
	fi
	if [[ "$1" == "-t" ]]
	then
		if [[ "$2" =~ ^[0-9.]+$ ]]
		then
			_TCP_TIMEOUT_READLINE="$2"
		else
			echo "error: bad value for timeout: $2"
		fi
		shift 2
	fi
	
	read -t $_TCP_TIMEOUT_READLINE -u $_TCP_FD ans
	
	if [ -z "$1" ]
	then
		echo -e "$ans"
	else
		ans="${ans//\\\'/\\\\'}"
		ans="${ans//\\/\\\\}"
		ans="${ans//\'/\'\"\'\"\'}"
		eval "$1='$ans'"
	fi
}
tcp-writeline()
{
	echo -e "$@" >&$_TCP_FD
}
tcp-close()
{
	eval "exec $_TCP_FD<&-"
}
