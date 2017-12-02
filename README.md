# yetibash
Collection of some practical easy-to-use bash-wrappers to promote faster bash-scripting.

You need to use the 'source' command in bash to import the functions from one of the libraries so that it can be used in your current shell and all subshells. Abstract example usage:

    #!/bin/bash
    source /path/to/library/lib-name.sh
    # Now use the library, all functions in it will _always_ start with the name of the library
    name-somefunction with args

# install

    cd /usr/local/share && git clone https://github.com/jetibest/yetibash && echo "source '$(pwd)/yetibash/scripts/lib.sh'" >> ~/.bashrc

# update

    cd yetibash && git pull

# source lib-archive.sh

    # archive-extract [filename]
    archive-extract myfiles.zip
    
    # archive-compress [directory|file]
    archive-compress mydirectory

# source lib-bash.sh

    # bash-epoch [ms|s]
    echo "The current epoch in milliseconds is: $(bash-epoch ms)"
    
    # bash-trap command [signal]
    bash-trap 'echo "Goodbye."'
    
    # bash-avgsysloadpct [time]
    echo "The average system load over the past 5 minutes is $(bash-avgsysloadpct 5m)%"
    
    # bash-memusagepct [mode]
    echo "The current RAM-memory usage is $(bash-memusagepct memory)%"
    
    # bash-cpuusagepct [duration]
    echo "The current CPU usage is $(bash-cpuusagepct)%"

# source lib-calc.sh

    # calc-math [expression]
    calc-math -r 'log(5)/0.2' #= 8

# source lib-http.sh

    http-request "http://example.org/..." "param1=val1" param2=val2"
    if [[ http-statuscode == 200 ]]
    then
        # use response data
        http-data > /tmp/file.html
        # or move file with response data
        mv http-file /tmp/file.html
    fi
    http-clean

# source lib-ssh.sh

    if ssh-open user@example.org
    then
        if ssh-exec script.sh
        then
            ssh-rsync-put -aH /local/directory/ /remote/directory/
            ssh-rsync-get -aH /some/remote/directory/ /some/other/local/directory/
        fi
    else
        echo 'Could not connect.'
    fi
    ssh-close

# source lib-subs.sh

    # subs-shift [ms] [filename]
    subs-shift -54000 subs/en.srt
    
    # writes fixed subtitles file to subs/en.shift.srt

# source lib-sync.sh

    if ! sync-wait 10
    then
        echo 'Could not acquire lock within 10 seconds, goodbye.'
        exit 1
    fi
    echo 'Lock acquired...'
    # ...
    exit 0

# source lib-tcp.sh

    # raw HTTP GET-request
    if tcp-connect example.com 80
    then
        tcp-writeline "GET /"
        while tcp-readline ln
        do
            echo -e "$ln"
        done
    fi
    # equivalent "one-liner"
    tcp-connect example.com 80 && tcp-writeline "GET /" && while tcp-readline;do continue;done

# disclaimer
Free to use, copy, edit, sell, abuse, I don't care. This software comes with no guarantees/responsibilities.
