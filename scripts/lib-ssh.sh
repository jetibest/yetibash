#!/bin/bash
#source=https://github.com/jetibest/yetibash/scripts/lib-ssh.sh

_SSH_SESSION_INFO_FORMAT="/tmp/ssh-session-?.info"
_SSH_SESSION_SOCKET_FORMAT="/tmp/ssh-session-?.socket"
_ssh_session_info=""
_ssh_session_socket=""
_ssh_session_id=""

ssh-help()
{
	topic="$1"
	
	
	if [[ "$topic" == "ssh-open" ]]
	then
		echo "ssh-open [-sop] [user@]host[:port]"
		echo "    Open ssh-connection for later use."
		echo "    "
	elif [[ "$topic" == "ssh-session-id" ]]
	then
		echo "ssh-session-id"
		echo "    Get the current session-id."
	elif [[ "$topic" == "ssh-rsync-get" ]]
	then
		echo "ssh-rsync-get [-so] [rsync options] source target"
		echo "    Do rsync on remote connection using the given ssh-connection."
		echo "    -s,--session [?.info|session-id]"
		echo "        Use a custom info-file or session-id."
		echo "    -o,--options option ..."
		echo "        Specify custom options for ssh."
		echo "    rsync options"
		echo "        Use '-aH' for filesystem backups."
		echo "        You might need '--protocol=29' to support older rsync."
		echo "    source"
		echo "        Trailing slash to prevent creating source directory in target."
	elif [[ "$topic" == "ssh-rsync-put" ]]
	then
		echo "ssh-rsync-put [-so] [rsync options] source target"
		echo "    Do rsync on remote connection using the given ssh-connection."
		echo "    -s,--session [?.info|session-id]"
		echo "        Use a custom info-file or session-id."
		echo "    -o,--options option ..."
		echo "        Specify custom options for ssh."
		echo "    rsync options"
		echo "        Use '-aH' for filesystem backups."
		echo "        You might need '--protocol=29' to support older rsync."
		echo "    source"
		echo "        Trailing slash to prevent creating source directory in target."
	elif [[ "$topic" == "ssh-exec []" ]]
	then
		echo "ssh-exec [-so] command [command-args]"
		echo "    Execute a command on the remote connection."
		echo "    -s,--session ?.info|session-id"
		echo "        Use a custom info-file or session-id."
		echo "    -o,--options option ..."
		echo "        Specify custom options for ssh."
	elif [[ "$topic" == "ssh-socket-info" ]]
	then
		echo "ssh-socket-info [id|socket|params] [?.info|session-id]"
		echo "    Get information about the connection from the info-file."
	elif [[ "$topic" == "ssh-close" ]]
	then
		echo "ssh-close [-f] [all|?.info]"
		echo "    Close ssh-connection."
		echo "    -f,--force"
		echo "        Forcefully close the connection (using exit instead of stop)."
	elif [[ "$topic" == "example" ]]
	then
		echo "Example:"
		echo "    if ssh-open user@example.org"
		echo "    then"
		echo "        if ssh-exec 'script.sh'"
		echo "        then"
		echo "            # Use a trailing slash on source directory to prevent creating new directory."
		echo "            ssh-rsync-put -aH '/local/a/directory/' '/remote/a/directory/'"
		echo "            ssh-rsync-get -aH '/remote/another/directory/' '/local/another/directory/'"
		echo "        fi"
		echo "    else"
		echo "        echo 'Could not connect.'"
		echo "    fi"
		echo "    ssh-close"
		echo ""
		echo "Example:"
		echo "    ssh-open user@example.org && ssh-exec 'script.sh'; ssh-close"
		echo ""
	else
		ssh-help example
		
		echo "Use the 'source' command in bash to include this script to use the commands below:"
		ssh-help ssh-open
		ssh-help ssh-rsync
		ssh-help ssh-exec
		ssh-help ssh-close
	fi
}
ssh-open()
{
	local session_id
	local options
	local port
	
	while [[ "${1:0:1}" == "-" ]]
	do
		if [[ "$1" == "-s" ]] || [[ "$1" == "--session" ]]
		then
			session_id="$2"
			shift 2
		
		elif [[ "$1" == "-o" ]] || [[ "$1" == "--options" ]]
		then
			options="$2"
			shift 2
		
		elif [[ "$1" == "-p" ]]
		then
			port="$2"
			shift 2
		
		elif [[ "$1" == "--" ]]
		then
			shift
			break
		
		else
			echo "warning: unknown option: $1" >&2
			shift
		fi
	done
	
	if [[ "$session_id" == "" ]]
	then
		session_id="$(date +'%s%N')"
	fi
	_ssh_session_socket="${_SSH_SESSION_SOCKET_FORMAT/\?/$session_id}"
	_ssh_session_info="${_SSH_SESSION_INFO_FORMAT/\?/$session_id}"
	
	local conn_info="$1"
	shift
	local user
	if [[ "$conn_info" =~ @ ]]
	then
		user="${conn_info%%@*}"
	else
		user="$(whoami)"
	fi
	if [[ "$user" != "" ]]
	then
		user="$user@"
	fi
	
	conn_info="${conn_info#*@}"
	local hostname="${conn_info%:*}"
	
	if ! [[ "$port" =~ ^[0-9]+$ ]]
	then
		if [[ "$conn_info" =~ : ]]
		then
			port="${conn_info##*:}"
		fi
		
		if ! [[ "$port" =~ ^[0-9]+$ ]] && [[ "$1" =~ ^[0-9]+$ ]]
		then
			port="$1"
			shift
		fi
	fi
	
	local port_param=""
	if [[ "$port" != "" ]]
	then
		port_param="-p $port"
	fi
	local login_params="$port_param $user$hostname"
	echo -e "$_ssh_session_id\n$_ssh_session_socket\n$port_param\n$user$hostname" > "$_ssh_session_info"
	
	if [ -e "$_ssh_session_socket" ]
	then
		ssh-close "$_ssh_session_socket"
	fi
	ssh $options -nNf -o ControlMaster="yes" -o ControlPath="$_ssh_session_socket" $login_params
}
ssh-session-id()
{
	echo "$_ssh_session_id"
}
ssh-rsync-get()
{
	local info_file="$_ssh_session_info"
	local options
	while [[ "${1:0:1}" == "-" ]]
	do
		if [[ "$1" == "-s" ]] || [[ "$1" == "--session" ]]
		then
			info_file="$2"
			shift 2
		
		elif [[ "$1" == "-o" ]] || [[ "$1" == "--options" ]]
		then
			# Note: These options are for SSH, not rsync
			options="$2"
			shift 2
		
		elif [[ "$1" == "--" ]]
		then
			shift
			break
		
		else
			break
		fi
	done
	
	local params=()
	while [[ "${1:0:1}" == "-" ]]
	do
		if [[ "$1" == "--" ]]
		then
			shift
			break
		else
			params+=("$1")
			shift
		fi
	done
	
	local sourcepath="$1"
	local targetpath="$2"
	
	rsync $params -e "ssh $options $(ssh-socket-info portparam "$info_file") -o ControlPath=$(ssh-socket-info socket "$info_file")" --protocol=29 "$(ssh-socket-info userhostparam "$info_file"):$sourcepath" "$targetpath"
}
ssh-rsync-put()
{
	local info_file="$_ssh_session_info"
	local options
	while [[ "${1:0:1}" == "-" ]]
	do
		if [[ "$1" == "-s" ]] || [[ "$1" == "--session" ]]
		then
			info_file="$2"
			shift 2
		
		elif [[ "$1" == "-o" ]] || [[ "$1" == "--options" ]]
		then
			# Note: These options are for SSH, not rsync
			options="$2"
			shift 2
		
		elif [[ "$1" == "--" ]]
		then
			shift
			break
		
		else
			break
		fi
	done
	
	local params=()
	while [[ "${1:0:1}" == "-" ]]
	do
		if [[ "$1" == "--" ]]
		then
			shift
			break
		else
			params+=("$1")
			shift
		fi
	done
	
	local sourcepath="$1"
	local targetpath="$2"
	
	rsync $params -e "ssh $options $(ssh-socket-info portparam "$info_file") -o ControlPath=$(ssh-socket-info socket "$info_file")" --protocol=29 "$sourcepath" "$(ssh-socket-info userhostparam "$info_file"):$targetpath"
}
ssh-exec()
{
	local info_file="$_ssh_session_info"
	local options
	while [[ "${1:0:1}" == "-" ]]
	do
		if [[ "$1" == "-s" ]] || [[ "$1" == "--session" ]]
		then
			info_file="$2"
			shift 2
		
		elif [[ "$1" == "-o" ]] || [[ "$1" == "--options" ]]
		then
			# Note: These options are for SSH, not rsync
			options="$2"
			shift 2
		
		elif [[ "$1" == "--" ]]
		then
			shift
			break
		
		else
			echo "warning: unknown option: $1" >&2
			shift
		fi
	done
	
	ssh $options -o ControlPath="$(ssh-socket-info socket "$info_file")" $(ssh-socket-info params "$info_file") "$@"
}
ssh-socket-info()
{
	local info_type="$1"
	local info_file="$2"
	
	if ! [ -e "$info_file" ] && [[ "$info_file" != "" ]]
	then
		# If file does not exist, then assume it is the session-id
		info_file="${_SSH_SESSION_INFO_FORMAT/\?/$info_file}"
	fi
	if ! [ -e "$info_file" ]
	then
		# If that is also not the case, use the current one
		info_file="$_ssh_session_info"
	fi
	
	if [[ "$info_type" == "id" ]]
	then
		head -n1 "$info_file"
		
	elif [[ "$info_type" == "socket" ]]
	then
		head -n2 "$info_file" | tail -n1
		
	elif [[ "$info_type" == "params" ]]
	then
		tail -n2 "$info_file" | tr '\n' ' '
		
	elif [[ "$info_type" == "portparam" ]]
	then
		tail -n2 "$info_file" | head -n1
		
	elif [[ "$info_type" == "userhostparam" ]]
	then
		tail -n1 "$info_file"
	else
		cat "$info_file"
	fi
}
ssh-close()
{
	local mode="stop"
	local files="$_ssh_session_info"
	local file
	local timeout_s=0
	
	while [[ "${1:0:1}" == "-" ]]
	do
		if [[ "$1" == "--force" ]] || [[ "$1" == "-f" ]]
		then
			mode="exit"
			shift
		
		elif [[ "$1" == "--" ]]
		then
			shift
			break
		
		else
			echo "warning: unknown option: $1" >&2
			shift
		fi
	done
	
	if [ -e "$1" ]
	then
		files="$1"
		shift
	
	elif [[ "$1" == "all" ]]
	then
		files=(${_SSH_SESSION_INFO_FORMAT/\?/*})
		shift
	
	elif [[ "$1" != "" ]]
	then
		file="${_SSH_SESSION_INFO_FORMAT/\?/$1}"
		if [ -e "$file" ]
		then
			files="$file"
		fi
		shift
	fi
	
	for file in "${files[@]}"
	do
		if [ -e "$file" ]
		then
			ssh -O "$mode" -o ControlPath="$(ssh-socket-info socket "$file")" $(ssh-socket-info params "$file")
			rm -f "$file"
		fi
	done
}
