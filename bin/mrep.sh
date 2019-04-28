#!/bin/bash
DEFAULT_FILTER='echo "${1%%=*}"'
DEFAULT_MATCH='[[ "$1" == "$2" ]]'

helpinfo()
{
          ################################################################################
    echo "MatchReplace commandline tool: mrep [options] [file]"
    echo ""
    echo "Usage: cat original.conf | mrep custom.conf > fixed.conf"
    echo ""
    echo "Options"
    echo "    -l, --line    Provide extra line separate from a given file. A given line "
    echo "                  takes precedence if also matching a line from the given file."
    echo "    -f, --filter  Provide Bash filter to match part of line."
    echo "                  Default filter: \`$DEFAULT_FILTER\`"
    echo "    -m, --match   Provide Bash comparison to match two filtered lines."
    echo "                  Default match: \`$DEFAULT_MATCH\`"
    echo ""
    echo "This program overrides lines in the standard input with lines from the given "
    echo "file, and writes the result to the standard  output. Lines are only overriden "
    echo "when they match after both having passed through the filter."
    echo ""
    echo "Example with default options"
    echo "/tmp/a.txt:"
    echo "a=1"
    echo "b=2"
    echo "c=3"
    echo "d=4"
    echo "d=5"
    echo "/tmp/b.txt:"
    echo "b=10"
    echo "b=12"
    echo "d=15"
    echo "$ cat /tmp/a.txt | mrep -l 'a=3' -l 'c=14' /tmp/b.txt"
    echo "a=3"
    echo "b=12"
    echo "c=14"
    echo "d=15"
    echo "d=15"
    echo ""
    echo "Example with custom options"
    echo "# Match if first 4 characters are equal:"
    echo "$ ... | mrep -f '"'echo "${1:0:4}"'"'"
    echo "# Match line if substring of a given line:"
    echo "$ ... | mrep -f '"'echo "$1"'"'"' -m '"'"'[[ "$1" != "" ]] && [[ "$2" == "$1"* ]]'"'"
    echo ""
}

# parse args
extralines=()
while [[ "${1:0:1}" == "-" ]]
do
    if [[ "$1" == "--" ]]
    then
        break

    elif [[ "$1" == "-l" ]] || [[ "$1" == "--line" ]]
    then
        extralines+=("$2")
        shift
    
    elif [[ "$1" == "-f" ]] || [[ "$1" == "--filter" ]]
    then
        filter="$2"
        shift
    
    elif [[ "$1" == "-m" ]] || [[ "$1" == "--match" ]]
    then
        match="$2"
        shift
    
    elif [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]
    then
        helpinfo
        exit 0
    
    fi
    
    shift
done

# default arg is override file
if [[ "$1" != "" ]] && [[ "$extrafile" == "" ]]
then
    extrafile="$1"
    shift
fi

# default match is $1 == $2
if [[ "$match" == "" ]]
then
    match="$DEFAULT_MATCH"
fi

# default match is grabbing key from key=value format
if [[ "$filter" == "" ]]
then
    filter="$DEFAULT_FILTER"
fi

# warning if file does not exist
if [[ "$extrafile" != "" ]] && ! [ -e "$extrafile" ]
then
    echo "Warning: The file '$extrafile' does not exist. Use -h or --help for correct usage." >&2
    extrafile=""
fi

# check if there's anything to replace
if [[ "$extrafile" == "" ]] && [[ "${extralines[@]}" == "" ]]
then
    echo "Warning: No lines found to replace, exiting. Use -h or --help to learn more." >&2
fi

# setup match and filter methods
match(){ eval "$match"; }
filter(){ eval "$filter"; }

# read line by line, and override from extrafile where needed
while IFS='' read -r -u 0 line || [[ -n "$line" ]]
do
    filteredline="$(filter "$line")"
    extralinefound=false
    extralinevalue=""
    
    if [[ "$extrafile" != "" ]]
    then
        exec 3<"$extrafile"
        while IFS='' read -r -u 3 extraline || [[ -n "$extraline" ]]
        do
            if match "$filteredline" "$(filter "$extraline")"
            then
                extralinevalue="$extraline"
                extralinefound=true
            fi
        done
        exec 3<&-
    fi
    
    for extraline in "${extralines[@]}"
    do
        if match "$filteredline" "$(filter "$extraline")"
        then
            extralinevalue="$extraline"
            extralinefound=true
        fi
    done
    
    if $extralinefound
    then
        echo "$extralinevalue"
    else    
        echo "$line"
    fi
done >&1
