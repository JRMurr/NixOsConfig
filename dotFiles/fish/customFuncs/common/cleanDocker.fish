function cleanDocker
    if read_confirm "Do you want to stop and remove all containers?"
        if docker ps -a -q | count > 0
            docker stop (docker ps -a -q)
            docker rm (docker ps -a -q)
        end
    end
end