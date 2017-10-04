#!/bin/bash
#https://github.com/jetibest/yetibash/scripts/lib-sync.sh

_SYNC_CACHE_FORMAT="/tmp/sync-pid-?.tmp"
_SYNC_FD="200"
_sync_lockfile=""

sync-help()
{
	topic="$1"
	
	if [[ "$topic" == "sync-kill" ]]
	then
		echo "sync-kill identifier"
		echo "    Kill the PID of by sync-identifier."
		
	elif [[ "$topic" == "sync-pidfile" ]]
	then
		echo "sync-pidfile"
		echo "    Print file-descriptor of the current flock."
	
	elif [[ "$topic" == "sync-release" ]]
	then
		echo "sync-release"
		echo "    Release the lock manually (automatically released on EXIT using trap)."
	
	elif [[ "$topic" == "sync-lock [identifier] [timeout in s]" ]]
	then
		echo "sync-lock "
		echo "    Wait until lock can be acquired (using flock)."
		echo "    The lock is automatically released upon EXIT using trap."
		echo "    Timeout can be a number in seconds, or Inf for infinite timeout. Does not wait by default (non-blocking)."
		echo "    Identifier defaults to the full path of the script."
	
	elif [[ "$topic" == "example" ]]
	then
		echo "Example:"
		echo "    source /.../.../lib-sync.sh"
		echo ""
		echo "    if ! sync-wait 10"
		echo "    then"
		echo "        echo 'Could not acquire lock within 10 seconds, goodbye.'"
		echo "        exit 1"
		echo "    fi"
		echo "    echo 'Lock acquired...'"
		echo "    # ..."
		echo "    exit 0"
		echo ""
		
	else
		sync-help example
		
		echo "Use the 'source' command in bash to include this script to use the commands below:"
		sync-help sync-kill
		sync-help sync-pidfile
		sync-help sync-release
		sync-help sync-lock
	fi
}
sync-kill()
{
	local name="$(echo "$1" | tr '/' '-')"
	pid="$(cat "${_SYNC_CACHE_FORMAT/\?/${name}}")"
	if [[ "$pid" =~ ^[0-9]+$ ]]
	then
		echo "$pid"
		kill "$pid"
		return $?
	else
		return 1
	fi
}
sync-pidfile()
{
	echo "/proc/$$/fd/$_SYNC_FD"
}
sync-release()
{
	if [[ "$_sync_lockfile" == "" ]]
	then
		_sync_lockfile="$(readlink -f "$0" | tr '/' '-')"
	fi
	
	echo "" > "${_SYNC_CACHE_FORMAT/\?/$_sync_lockfile}"
	_sync_lockfile=""
	
	eval "exec $_SYNC_FD<&-"
	
	return $?
}
sync-lock()
{
	# Note: Waiting order is not guaranteed, it is "random". There is no queue.
	# Note: Writing an empty line to the lockfile is essential, instead of removing the file after use.
	#       Because other instances that are queued to sync will not recreate the file.
	
	if [[ "$1" == "" ]]
	then
		_sync_lockfile="$(readlink -f "$0" | tr '/' '-')"
	elif ! [[ "$1" =~ ^[0-9]+$ ]] && [[ "$1" != "Inf" ]]
	then
		_sync_lockfile="$(echo "$1" | tr '/' '-')"
		shift
	fi
	
	local timeout_s="$1"
	local flock_params="\"$_SYNC_FD\""
	
	if [[ "$timeout_s" == "Inf" ]]
	then
		timeout_s=-1
	elif ! [[ "$timeout_s" =~ ^[0-9]+$ ]]
	then
		timeout_s=0
	else
		timeout_s=$((timeout_s * 10))
	fi
	
	_sync_lockfile="${_SYNC_CACHE_FORMAT/\?/$_sync_lockfile}"
	
	eval "exec $_SYNC_FD>\"$_sync_lockfile\""
	
	if [ "$timeout_s" -eq 0 ]
	then
		flock_params="-n \"$_SYNC_FD\""
		
	elif [ "$timeout_s" -gt 0 ]
	then
		flock_params="-w \"$timeout_s\" \"$_SYNC_FD\""	
	fi
	
	if flock $flock_params
	then
		# Note: Please be careful when using trap as sync-wait relies on it, it is recommended to use trap-append (source lib-bash.sh).
		local signal_name="EXIT"
		local commands="echo \"\" > \"$_sync_lockfile\""
		trap-append "$signal_name" "$commands" 2>/dev/null || trap "eval '$(trap -p | sed -E -e '/.*'"$signal_name"'$/'\!'d' -e 's/^trap -- '"'"'(.*)'"'"' '"$signal_name"'$/\1/')'${commands}" "$signal_name"
		echo $$ 1>&200
		return 0
	else
		return 1
	fi
}
