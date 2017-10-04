# yetibash
Collection of some practical easy-to-use bash libraries to promote faster bash-scripting.
See below for examples.

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

# disclaimer
Free to use, copy, edit, sell, abuse, I don't care. This software comes with no guarantees/responsibilities.
