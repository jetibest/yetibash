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
	
	elif [[ "$topic" == "bash-avgsysloadpct" ]]
	then
		echo "bash-avgsysloadpct [time]"
		echo "    Print average system load percentage (using /proc/loadavg)."
		echo "    Result is normalized using the number of processors."
		echo "    Default time is 1m. Possible values are: 1m, 5m, or 15m."
		echo "    (m is minute)"
	
	elif [[ "$topic" == "bash-memusagepct" ]]
	then
		echo "bash-memusagepct [mode]"
		echo "    Print current memory usage percentage (using /proc/meminfo)."
		echo "    Default mode is memory. Possible values are: memory, swap, all, list."
		echo "      memory is RAM memory usage percentage"
		echo "      swap is swap memory usage percentage"
		echo "      all is memory and swap combined"
		echo "      list prints separate memory and swap values in bytes"
	
	elif [[ "$topic" == "bash-cpuusagepct" ]]
	then
		echo "bash-cpuusagepct [duration]"
		echo "    Print current CPU usage percentage (using /proc/stat)."
		echo "    Duration is time to measure in milliseconds."
		echo "    Default duration is 200ms."
	
	elif [[ "$topic" == "example" ]]
	then
		echo "Example:"
		echo "    source /.../.../lib-bash.sh"
		echo ""
		echo "    echo \"The current epoch in milliseconds is: \$(bash-epoch ms)\""
		echo ""
		echo "    bash-trap 'echo \"Goodbye.\"'"
		echo ""
		echo "    echo \"The average system load over the past 5 minutes is \$(bash-avgsysloadpct 5m)%\""
		echo ""
		echo "    echo \"The current memory usage is \$(bash-memusagepct)%\""
		echo ""
		echo "    echo \"The current CPU usage is \$(bash-cpuusagepct)%\""
		echo ""
		echo ""
		
	else
		bash-help example
		
		echo "Use the 'source' command in bash to include this script to use the commands below:"
		bash-help bash-epoch
		bash-help bash-trap
		bash-help bash-avgsysloadpct
		bash-help bash-memusagepct
		bash-help bash-cpuusagepct
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
bash-avgsysloadpct()
{
	local column='$1'
	
	if [[ "$1" == "15m" ]]
	then
		column='$3'
	
	elif [[ "$1" == "5m" ]]
	then
		column='$2'
	fi
	
	awk '{print int(0.5+100*'"$column"'/'"$(grep '^processor' /proc/cpuinfo | wc -l)"')}' /proc/loadavg
}
bash-memusagepct()
{
	local mode="$1"
	local result="-"
	
	if [[ "$mode" == "list" ]]
	then
		result="$(awk '/B$/{mult=1}/kB$/{mult=1000}/MB$/{mult=1000*1000}/GB$/{mult=1000*1000*1000}/KiB$/{mult=1024}/MiB$/{mult=1024*1024}/GiB$/{mult=1024*1024*1024}/^MemTotal:/{t=$2*mult;i=i+1}/^SwapTotal:/{st=$2*mult;i=i+1}/^SwapFree:/{s=$2*mult;i=i+1}/^MemFree:/{f=$2*mult;i=i+1}/^Buffers:/{b=$2*mult;i=i+1}/^Cached:/{c=$2*mult;i=i+1}i==6{exit}END{if(t){print "MemFree:\t" (f + b + c);print "MemUsed:\t" (t - f - b - c);print "MemTotal:\t" t;print "SwapFree:\t" s;print "SwapUsed:\t" (st-s);print "SwapTotal:\t" st}else{print "-"}}' /proc/meminfo)"
	
	elif [[ "$mode" == "swap" ]]
	then
		result="$(awk '/^SwapTotal:/{t=$2;i=i+1}/^SwapFree:/{s=$2;i=i+1}i==2{exit}END{if(t){print int(0.5+100*(t-s)/t)}else{print "-"}}' /proc/meminfo)"

	elif [[ "$mode" == "all" ]]
	then
		result="$(awk '/^MemTotal:/{t=$2;i=i+1}/^SwapTotal:/{st=$2;i=i+1}/^SwapFree:/{s=$2;i=i+1}/^MemFree:/{f=$2;i=i+1}/^Buffers:/{b=$2;i=i+1}/^Cached:/{c=$2;i=i+1}i==6{exit}END{if(t){print int(0.5+100*(t + st - f - b - c - s)/(t + st))}else{print "-"}}' /proc/meminfo)"

	else # mode == memory
		result="$(awk '/^MemTotal:/{t=$2;i=i+1}/^MemFree:/{f=$2;i=i+1}/^Buffers:/{b=$2;i=i+1}/^Cached:/{c=$2;i=i+1}i==4{exit}END{if(t){print int(0.5+100*(t - f - b - c)/t)}else{print "-"}}' /proc/meminfo)"
	fi
	
	echo "$result"
	
	if [[ "$result" == "-" ]]
	then
		return 1
	fi
}
bash-cpuusagepct()
{
	local delay_ms="$1"
	if ! [[ "$delay_ms" =~ ^[0-9]+$ ]]
	then
		delay_ms="200"
	fi
	{ head -n1 /proc/stat && sleep "$((delay_ms/1000)).$((delay_ms - delay_ms/1000*1000))" && head -n1 /proc/stat; } | awk '/^cpu /{u=$2-u;s=$4-s;i=$5-i;w=$6-w}END{t=u+s+i+w;print int(0.5+100*(t-i)/t)}'
}
