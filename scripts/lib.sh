#!/bin/bash
#source=https://github.com/jetibest/yetibash/scripts/lib.sh

if [[ "$0" =~ lib.sh$ ]]
then
    echo "Usage: source /path/to/scripts/lib.sh"
    exit 1
fi
if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]
then
    echo "Sources all libraries in this directory to use their functions."
    echo "Usage:"
    echo "    source /path/to/scripts/lib.sh"
    echo "It is recommended to add this to your .bashrc:"
    echo "    echo 'source \"/path/to/scripts/lib.sh\"' >> ~/.bashrc"
    exit 0
fi

scripts=( "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"/lib-*.sh )
for lib in "${scripts[@]}"
do
  source "$lib"
done
