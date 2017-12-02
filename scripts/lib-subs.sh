#!/bin/bash
#source=https://github.com/jetibest/yetibash/scripts/lib-subs.sh

subs-help()
{
	local topic="$1"
	
	if [[ "$topic" == "subs-shift" ]]
	then
		echo "subs-shift [ms] [filename]"
		echo "    Shift all times of a .srt subtitles-file with the given time in milliseconds."
		echo "    Writes to a new file: filename.shift.srt, overwrites without confirmation."
		echo "    May be both positive or negative."
		echo ""
		echo "    Usage details:"
		echo "    First, use a mediaplayer to determine the exact offset that is needed to change."
		echo "    This is specifically useful when the offset is more than a few seconds, as some mediaplayers do not handle that well."
	
	elif [[ "$topic" == "example" ]]
	then
		echo "Example:"
		echo "    subs-shift 54000 subs/en.srt"
		echo ""
	else
		subs-help example
		
		echo "Use the 'source' command in bash to include this script to use the commands below:"
		subs-help subs-shift
	fi
}

subs-shift()
{
	if [ $# -ne 2 ]
	then
		echo "Usage: subs-shift [milliseconds to shift] [file.srt]"
		echo "Will output to file.shift.srt."
		return 1
	fi
	shift_ms="$1"
	if ! [[ "$shift_ms" =~ ^[0-9-]+$ ]]
	then
		echo "First argument should be the number of milliseconds to shift."
		return 1
	fi
	filename="$2"
	if ! [ -f "$filename" ]
	then
		echo "Second argument should be the srt-file to process."
		return 1
	fi
	
	# Shift all timestamps in file with the given number of milliseconds
	echo "Shifting all timestamps in file ($filename) with $shift_ms milliseconds, to: ${filename%.srt}.shift.srt"
	cat "$filename" | awk '{if($0~/[0-9]+:[0-9]+:[0-9]+,[0-9]+/){while(match($0, /[0-9:,]+/)){if(RSTART > 1){printf "%s", substr($0, 1, RSTART - 1);}t=substr($0, RSTART, RLENGTH);$0=substr($0, RSTART + RLENGTH);i=3600000;sum_ms=0;while(match(t, /[0-9]+/)){t_i=substr(t, RSTART, RLENGTH);t=substr(t, RSTART + RLENGTH);sum_ms=sum_ms + t_i*i;i=i/60;if(i<1000){i=1;}}sum_ms=int(sum_ms + 1*'"$shift_ms"');if(sum_ms<0){sum_ms=0;}printf "%s,%03d", strftime("%H:%M:%S", sum_ms/1000, 1), sum_ms%1000;}if($0 != ""){print $0}else{print ""}}else{print $0}}' > "${filename%.srt}.shift.srt"
}
