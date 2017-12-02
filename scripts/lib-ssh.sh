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
	elif [[ "$topic" == "ssh-exec" ]]
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
	elif [[ "$topic" == "ssh-keyselect-local" ]]
	then
		echo "warning: ssh-keyselect-local is EXPERIMENTAL. May not be implemented yet."
	elif [[ "$topic" == "ssh-keygen-remote" ]]
	then
		echo "warning: ssh-keygen-remote is EXPERIMENTAL. May not be implemented yet."
	elif [[ "$topic" == "ssh-nopasswordsetup" ]]
	then
		echo "warning: ssh-nopasswordsetup is EXPERIMENTAL. May not be implemented yet."
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
		ssh-help ssh-session-id
		ssh-help ssh-rsync-get
		ssh-help ssh-rsync-put
		ssh-help ssh-exec
		ssh-help ssh-socket-info
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
ssh-keyselect-local()
{
	local key_file=""
	local key_file_exclude=""
	
	# Find and select a key-file in ~/.ssh/
	local results=(~/.ssh/id_*.pub)
	if [ "${#results[@]}" -gt 0 ]
	then
		if [ "${#results[@]}" -eq 1 ]
		then
			key_file="${results[0]}"
			if [ -e "$key_file" ]
			then
				echo "Existing key found: $key_file"
				read -p "Use this one? ([y]/n): " answer
				if [[ "$answer" == "n" ]]
				then
					key_file_exclude="$key_file"
					key_file=""
				fi
			fi
		else
			echo "Existing keys found:"
			for i in "${!results[@]}"
			do
				echo "  $((i + 1)). ${results[i]}"
			done
			while true
			do
				read -p "Select key (1-${results[i]} or leave empty): " answer
				if [[ "$answer" =~ ^[0-9]+$ ]]
				then
					key_file="${results[$((answer - 1))]}"
				
				elif [[ "$answer" != "" ]]
				then
					echo "Invalid number. Leave empty to select none."
				else
					break
				fi
			done
		fi
	fi
	
	# Create new key if not found
	if ! [ -e "$key_file" ]
	then
		if [[ "$key_file" == "" ]]
		then
			echo "No existing key found in ~/.ssh/"
		else
			echo "Key not found: $key_file"
		fi
		
		read -n 1 -p "Create new key? ([y]/n): " answer
		if [[ "$answer" != "n" ]]
		then
			echo "Note: You can use an empty passphrase."
			read -p "Number of bits in the key (default=4096): " bits_count
			if ! [[ "$bits_count" =~ ^[0-9]+$ ]]
			then
				bits_count="4096"
			fi
			
			local keygen_result="$(ssh-keygen -b "$bits_count")"
			key_file="$(echo -e "$keygen_result" | sed -E -e '/^public key.*saved/!d' -e 's/^[^/]*(.*)\.$/\1/')"
			
			if ! [ -e "$key_file" ]
			then
				local results=(~/.ssh/id_*.pub)
				key_file="${results[0]}"
				
				if ! [ -e "$key_file" ] || [[ "$key_file_exclude" == "$key_file" ]]
				then
					echo "error: no ssh-key selected"
					return 1
				fi
			fi
		else
			echo "error: no ssh-key selected"
			return 1
		fi
	fi
	
	echo "ssh-key selected: $key_file"
}
ssh-keygen-remote()
{
	echo "error: not implemented yet"
}
ssh-nopasswordsetup()
{
	local key_file
	
	while [[ "${1:0:1}" == "-" ]]
	do
		if [[ "$1" == "-k" ]] || [[ "$1" == "--key-file" ]]
		then
			key_file="$2"
			shift 2
		
		elif [[ "$1" == "--" ]]
		then
			shift
			break
		else
			break
		fi
	done
	
	# Ensure to find a local key-file
	if ! [ -e "$key_file" ]
	then
		key_file="$(ssh-keygen-local)"
		
		if ! [ -e "$key_file" ]
		then
			echo "error: no ssh-key."
			return 1
		fi
	fi
	
	# Extract .ssh directory
	local ssh_dir="${key_file%/*}"
	# Ensure non-empty directory
	[ "$ssh_dir" ] || ssh_dir="."
	
	# Ensure correct permissions on .ssh directory and files in it
	chmod 700 "$ssh_dir" || echo "warning: failed to execute: chmod 700 '$ssh_dir'"
	touch "$ssh_dir/known_hosts" && chmod 644 "$ssh_dir/known_hosts" || echo "warning: failed to execute: touch '$ssh_dir/known_hosts' && chmod 644 '$ssh_dir/known_hosts'"
	touch "$ssh_dir/authorized_keys" && chmod 600 "$ssh_dir/authorized_keys" || echo "warning: failed to execute: touch '$ssh_dir/authorized_keys && chmod 600 '$ssh_dir/authorized_keys'"
	
	# Add remote host to known_hosts
	# TODO
	local local_host="domain name"
	local local_addresses="ip addresses"
	local local_port="poort"
	local remote_user="user"
	local remote_host="domain name"
	local remote_port="poort"
	
	if ! grep -q "$remote_host" "$ssh_dir/known_hosts"
	then
		ssh-keyscan -p "$remote_port" "$remote_host" >> "$ssh_dir/known_hosts"
	fi
	
	# Add all possible IP-addresses that are bound to this domain (if it is already an IP, it will just return no address)
	local remote_addresses=($(getent hosts "$remote_host" | awk '{print $1}'))
	for remote_address in "${remote_addresses[@]}"
	do
		if ! grep -q "$remote_address" "$ssh_dir/known_hosts"
		then
			ssh-keyscan -p "$remote_port" "$remote_address" >> "$ssh_dir/known_hosts"
		fi
	done
	
	# This is a two-way installation, I think maybe we should be explicit in which way to install the connection
	# Install public key on remote host
	if ssh-open "$remote_user@$remote_host:$remote_port"
	then
		cat "$key_file" | ssh-exec -o "-o PubkeyAuthentication=no -o PreferredAuthentications=password" 'cat > /tmp/tmpkey.pub;mkdir -p .ssh;chmod 700 .ssh;touch .ssh/known_hosts;chmod 644 .ssh/known_hosts;touch .ssh/authorized_keys;chmod 600 .ssh/authorized_keys;if ! grep "$(cat /tmp/tmpkey.pub | awk '"'"'{print $NF}'"'"')" .ssh/authorized_keys; then cat /tmp/tmpkey.pub >> .ssh/authorized_keys; fi; rm -f /tmp/tmpkey.pub'
		ssh-exec 'if ! grep -q "'"$local_host"'" .ssh/known_hosts; then ssh-keyscan -p "'"$local_port"'" "'"$local_host"'" >> .ssh/known_hosts; fi'
	#	if local_domain
	#	ssh-exec 'if ! grep -q "'"$local_domain"'" .ssh/known_hosts; then ssh-keyscan -p "'"$local_port"'" "'"$local_domain"'" >> .ssh/known_hosts; fi'
	#	fi
		
		# Which version is correct? it depends... or does it?
		ssh -o '-t' 'ssh-copy-id -i .ssh/id_dsa.pub "'"$local_user"'@'"$local_host"' -p '"$current_port"'"'
		ssh -o '-t' 'ssh-copy-id -i .ssh/id_dsa.pub "'"$local_user"'@'"$local_host"'" -p '"$current_port"''
		
	fi
	ssh-close
	
	#TODO
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
