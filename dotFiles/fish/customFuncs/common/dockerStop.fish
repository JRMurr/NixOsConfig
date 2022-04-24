function dockerStop --wraps="docker rm" 
    docker stop $argv
    docker rm $argv
end