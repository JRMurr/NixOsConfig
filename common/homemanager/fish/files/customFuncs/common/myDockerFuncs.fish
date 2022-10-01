function dUp --wraps "docker-compose up"
    docker-compose up $argv
end

function dDown --wraps "docker-compose down"
    docker-compose down $argv
end