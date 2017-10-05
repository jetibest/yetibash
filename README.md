# yetibash
Collection of some practical easy-to-use bash libraries to promote faster bash-scripting.
See below for examples.

# source lib-bash.sh

    # bash-epoch [ms|s]
    echo "The current epoch in milliseconds is: $(bash-epoch ms)"
    
    # bash-trap command [signal]
    bash-trap 'echo "Goodbye."'

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

# source lib-sync.sh

    if ! sync-wait 10
    then
        echo 'Could not acquire lock within 10 seconds, goodbye.'
        exit 1
    fi
    echo 'Lock acquired...'
    # ...
    exit 0

# disclaimer
Free to use, copy, edit, sell, abuse, I don't care. This software comes with no guarantees/responsibilities.
