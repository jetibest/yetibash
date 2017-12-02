#!/bin/bash
#source=https://github.com/jetibest/yetibash/scripts/lib-calc.sh

calc-help()
{
	topic="$1"
	
	if [[ "$topic" == "calc-convertunits" ]]
	then
		echo "calc-convertunits from [round] to"
		echo "    Print epoch (using date)."
		echo "    Optional round parameter returns an integer value."
	
	elif [[ "$topic" == "calc-math" ]]
	then
		echo "calc-math [options] [expression]"
		echo "    Calculates a given mathematical expression (using awk, up to ~2^1024)."
		echo "    Options:"
		echo "      --round, -r    Round result to nearest integer."
		echo "      --floor        Floor result to lower integer."
		echo "      --ceil         Ceil result to upper integer."
	
	elif [[ "$topic" == "example" ]]
	then
		echo "Example:"
		echo "    source /.../.../lib-calc.sh"
		echo ""
		echo "    echo \"3 feet are \$(calc-convertunits 3ft round yard) yards.\""
		echo ""
		echo "    echo \"1500ms are \$(calc-convertunits 1500ms) seconds.\""
		echo ""
		echo "    echo \"-5*3^2.5 + 123.567 = \$(calc-math '-5*3^2.5 + 123.567')\""
		echo ""
		echo ""
	else
		calc-help example
		
		echo "Use the 'source' command in bash to include this script to use the commands below:"
		calc-help calc-convertunits
		calc-help calc-math
	fi
}
calc-convertunits()
{
	# todo: make code below more generic and specify separate document with accurate conversion values
	# todo: area, volume, temperature, mass, luminous intensity
	
	local floatparam=""
	local floatwrap="printf \"%f\\n\", ("
	local sourcevalue="${1%%[^0-9.-]*}"
	local sourceunit="${1##*[0-9]}"
	if [[ "$2" == "round" ]]
	then
		floatparam="round"
		floatwrap="print int(0.5+"
		shift
	fi
	local targetunit="$2"
	
	
	if [[ "$sourceunit" == "yard" ]]
	then
		calc-convertunits "$(awk '{printf "%f", ($0*0.9144)}' <<< "$sourcevalue")m" $floatparam "$targetunit"
	
	elif [[ "$sourceunit" == "inches" ]] || [[ "$sourceunit" == "\"" ]] || [[ "$sourceunit" == "inch" ]] || [[ "$sourceunit" == "in" ]]
	then
		calc-convertunits "$(awk '{printf "%f", ($0*0.0254)}' <<< "$sourcevalue")m" $floatparam "$targetunit"
	
	elif [[ "$sourceunit" == "foot" ]] || [[ "$sourceunit" == "feet" ]] || [[ "$sourceunit" == "'" ]] || [[ "$sourceunit" == "ft" ]]
	then
		calc-convertunits "$(awk '{printf "%f", ($0*0.3048)}' <<< "$sourcevalue")m" $floatparam "$targetunit"
	
	elif [[ "$sourceunit" =~ s$ ]] # Time
	then
		local m=1
		local d=1
		
		if [[ "$sourceunit" == "ns" ]]
		then
			d=1000000000
			
		elif [[ "$sourceunit" == "us" ]]
		then
			d=1000000
			
		elif [[ "$sourceunit" == "ms" ]]
		then
			d=1000
		fi
		
		if [[ "$targetunit" == "ns" ]]
		then
			m=1000000000
			
		elif [[ "$targetunit" == "us" ]]
		then
			m=1000000
			
		elif [[ "$targetunit" == "ms" ]]
		then
			m=1000
		fi
		
		awk '{'"$floatwrap$m/$d"'*$0)}' <<< "$sourcevalue"
	
	elif [[ "$sourceunit" =~ m$ ]] # Distance
	then
		local d=1
		
		if [[ "$sourceunit" == "nm" ]]
		then
			d=1000000000
			
		elif [[ "$sourceunit" == "um" ]]
		then
			d=1000000
			
		elif [[ "$sourceunit" == "mm" ]]
		then
			d=1000
			
		elif [[ "$sourceunit" == "cm" ]]
		then
			d=100
			
		elif [[ "$sourceunit" == "dm" ]]
		then
			d=10
			
		elif [[ "$sourceunit" == "hm" ]]
		then
			d="0.01"
		
		elif [[ "$sourceunit" == "km" ]]
		then
			d="0.001"
		fi
		
		if [[ "$targetunit" =~ m$ ]]
		then
			local m=1
			
			if [[ "$targetunit" == "nm" ]]
			then
				m=1000000000
				
			elif [[ "$targetunit" == "um" ]]
			then
				m=1000000
				
			elif [[ "$targetunit" == "mm" ]]
			then
				m=1000
				
			elif [[ "$targetunit" == "cm" ]]
			then
				m=100
				
			elif [[ "$targetunit" == "dm" ]]
			then
				m=10
				
			elif [[ "$targetunit" == "hm" ]]
			then
				m="0.01"
				
			elif [[ "$targetunit" == "km" ]]
			then
				m="0.001"
			fi
			
			awk '{'"$floatwrap$m/$d"'*$0)}' <<< "$sourcevalue"
		
		elif [[ "$targetunit" == "yard" ]]
		then
			awk '{'"$floatwrap"'$0/0.9144/'"$d"')}' <<< "$sourcevalue"
		
		elif [[ "$targetunit" == "inches" ]] || [[ "$targetunit" == "\"" ]] || [[ "$targetunit" == "inch" ]] || [[ "$targetunit" == "in" ]]
		then
			awk '{'"$floatwrap"'$0/0.0254/'"$d"')}' <<< "$sourcevalue"
			
		elif [[ "$targetunit" == "foot" ]] || [[ "$targetunit" == "feet" ]] || [[ "$targetunit" == "'" ]] || [[ "$targetunit" == "ft" ]]
		then
			awk '{'"$floatwrap"'$0/0.3048/'"$d"')}' <<< "$sourcevalue"
			
		fi
	fi
}
calc-math()
{
	local formatstr="%f"
	local roundingarg="("
	while [[ "${1:0:1}" == "-" ]]
	do
		if [[ "$1" == "--round" ]] || [[ "$1" == "-r" ]]
		then
			roundingarg="int(0.5+"
			formatstr="%i"
			shift
			
		elif [[ "$1" == "--floor" ]]
		then
			roundingarg="int("
			formatstr="%i"
			shift
			
		elif [[ "$1" == "--ceil" ]]
		then
			roundingarg="int(1.0+"
			formatstr="%i"
			shift
		else
			break
		fi
	done
	
	local mathexpr="$1"
	awk '{printf "'"$formatstr"'\n", '"$roundingarg$mathexpr"');exit}' <<< ""
}
