#!/bin/bash
#source=https://github.com/jetibest/yetibash/scripts/lib-archive.sh

archive-help()
{
	topic="$1"
	
	if [[ "$topic" == "archive-extract" ]]
	then
		echo "archive-extract [filename]"
		echo "    Extract an archive to directory of the same name."
		echo "    Supported formats:"
		echo "        .tar.gz"
		echo "        .zip"
	
	elif [[ "$topic" == "archive-compress" ]]
	then
		echo "archive-compress [directory|filename]"
		echo "    Compress a file or directory recursively into a zip-file."
		echo "    Only .zip is supported."
	
	elif [[ "$topic" == "example" ]]
	then
		echo "Example:"
		echo "    source /.../.../lib-archive.sh"
		echo ""
		echo "    archive-extract /path/to/archive.zip"
		echo "    cd /path/to/archive && ls -la"
		echo ""
		echo "    archive-compress myfiles"
		echo "    ls -la myfiles.zip"
		echo ""
		
	else
		archive-help example
		
		echo "Use the 'source' command in bash to include this script to use the commands below:"
		archive-help archive-extract
		archive-help archive-compress
	fi
}

archive-extract()
{
	archive="$1"
	extractionpath="$1"
	if [[ "$archive" =~ .tar.gz$ ]]
	then
		extractionpath="${extractionpath%.tar.gz}"
		mkdir "$extractionpath" && tar -xf "$archive" -C "$extractionpath"
	elif [[ "$archive" =~ .zip$ ]]
	then
		extractionpath="${extractionpath%.zip}"
		mkdir "$extractionpath" && unzip "$archive" -d "$extractionpath"
	else
		echo "error: unsupported format"
	fi
}
archive-compress()
{
	directory="$1"
	dirpath="${directory%/*}"
	filename="${directory##*/}"
	cd "$dirpath" && zip -r "$filename.zip" "$directory"
}

