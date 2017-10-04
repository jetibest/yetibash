#!/bin/bash
#source=https://github.com/jetibest/yetibash/scripts/lib-bash.sh

bash-help()
{
	topic="$1"
	
	if [[ "$topic" == "bash-epoch" ]]
	then
		echo "bash-epoch [ms|s]"
		echo "    Print epoch (using date)."
		echo "    Default unit is seconds."
	
	elif [[ "$topic" == "bash-trap" ]]
	then
		echo "bash-trap command [signal]"
		echo "    Append a new command to the signal-trap."
		echo "    Default signal is EXIT."
		echo "    Note: Keep the command simple (wrap complex commands in a function)."
		echo "          Otherwise test carefully, because the trap is not parsed."
	
	elif [[ "$topic" == "example" ]]
	then
		echo "Example:"
		echo "    source /.../.../lib-bash.sh"
		echo ""
		echo "    echo \"The current epoch in milliseconds is: \$(bash-epoch ms)\""
		echo ""
		echo "    bash-trap 'echo \"Goodbye.\"'"
		echo ""
	
	else
		bash-help example
		
		echo "Use the 'source' command in bash to include this script to use the commands below:"
		bash-help bash-epoch
		bash-help bash-trap
	fi
}
bash-epoch()
{
	if [[ "$1" == "ms" ]]
	then
		echo "$(($(date '+%s%N')/1000000))"
	else
		echo "$(date '+%s')"
	fi
}
bash-trap()
{
	local cmd="$1"
	shift
	local signal_params=($@)
	local signal_name
	local trapped
	
	if [[ "$signal_params" == "" ]]
	then
		signal_params="EXIT"
	fi
	
	for signal_name in "${signal_params[@]}"
	do
		trapped="$(trap -p | sed -E -e '/.*'"$signal_name"'$/'\!'d' -e 's/^trap -- '"'"'(.*)'"'"' '"$signal_name"'$/\1/')"
		
		if [[ "$trapped" == "" ]]
		then
			trap "$cmd" "$signal_name"
		else
			trap "$trapped;$cmd" "$signal_name"
		fi
	done
}
