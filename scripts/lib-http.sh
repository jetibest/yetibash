#!/bin/bash
#source=https://github.com/jetibest/yetibash/scripts/lib-http.sh

_HTTP_CACHE_FORMAT="/tmp/http-response-%s%N.tmp"
_http_statuscode=0
_http_outputfile=""

http-help()
{
	topic="$1"
	
	if [[ "$topic" == "http-clean" ]]
	then
		echo "http-clean [all]"
		echo "    Remove last cached response."
		echo "    Use 'all' parameter to remove all cached response with a wildcard."
	
	elif [[ "$topic" == "http-data" ]]
	then
		echo "http-data"
		echo "    Print last response data to stdout (using cat)."
	
	elif [[ "$topic" == "http-file" ]]
	then
		echo "http-file"
		echo "    Print filename of last response data to stdout."
	
	elif [[ "$topic" == "http-statuscode" ]]
	then
		echo "http-statuscode"
		echo "    Print last response HTTP-statuscode to stdout."
	
	elif [[ "$topic" == "http-request" ]]
	then
		echo "http-request [-o /tmp/res.html] HTTP-url [param1=value1] [param2=value2] [...]"
		echo "    Do HTTP-request with given parameters to be URI-encoded (GET-request with curl)."
		echo "    If no output-file parameter, then uses temporary file."
		echo "    'http-help example' for an example."
	
	elif [[ "$topic" == "example" ]]
	then
		echo "Example:"
		echo "    source /.../.../lib-http.sh"
		echo ""
		echo "    http-request \"http://example.org/...\" \"param1=val1\" \"param2=val2\" [...]"
		echo "    if [[ http-statuscode == 200 ]]"
		echo "    then"
		echo "        http-data > /tmp/file.html          # Access to raw source code of response"
		echo "        mv \"\$(http-file)\" /tmp/file.html # Atomic move to new file is fastest"
		echo "    fi"
		echo "    http-clean                              # Clean cache (optional)"
		echo ""
	else
		http-help example
		
		echo "Use the 'source' command in bash to include this script to use the commands below:"
		http-help http-clean
		http-help http-data
		http-help http-file
		http-help http-statuscode
		http-help http-request
	fi
}
http-clean()
{
	if [[ "$1" == "all" ]]
	then
		rm -f "${_HTTP_CACHE_FORMAT//\%?/*}"
		return $?
	else
		if [[ "$_http_outputfile" != "" ]]
		then
			rm -f "$_http_outputfile"
			_http_outputfile=""
			return 0
		else
			return 1
		fi
	fi
}
http-data()
{
	cat "$_http_outputfile"	
}
http-file()
{
	echo "$_http_outputfile"
}
http-statuscode()
{
	echo "$_http_statuscode"
}
http-request()
{
	local file="$_HTTP_CACHE_FORMAT"
	if [[ "$1" == "--output" ]] || [[ "$1" == "-o" ]]
	then
		file="$2"
		shift 2
	fi
	
	local url="$1"
	shift 1
	
	local params=()
	for param in "$@"
	do
		params+=("--data-urlencode" "$param")
	done
	
	_http_outputfile="$(date +"$file")"
	_http_statuscode="$(curl -G -s -o "$_http_outputfile" -w "%{http_code}" "${params[@]}" "$url")"
	
	# Check if request succeeded and we received a response
	if [ $? -eq 0 ] && [[ "$_http_statuscode" =~ ^[0-9]+$ ]]
	then
		# Ensure file exists (if response body is empty, curl won't create it)
		touch "$_http_outputfile"
		return 0
	else
		# Ensure file does not exist (and reset name too)
		rm -f "$_http_outputfile" >/dev/null 2>&1
		_http_outputfile=""
		return 1
	fi
}
