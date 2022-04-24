function buildDevPost
    if read_confirm "Do you want to stop and rebuild the pg container?"
        killPg
        pushd $BODATA_DIR
        if not make db MAKE_JOBS=4
            popd
            return 1
        end
        popd
        pushd $BODATA_DIR/postgresql
        docker build -t immuta-db-dev -f DevDocker .
        # docker run -d -p 5432:5432 -v ${PWD}:/src --name=immuta-db-dev -e IMMUTA_REMOTE_QUERY=true --add-host=service.immuta:10.0.2.2 -it immuta-db-dev 
        # docker run -d --cap-add=SYS_PTRACE --cap-add=SYS_TIME --security-opt seccomp=unconfined -e IMMUTA_REMOTE_QUERY=true -p 5432:5432 -v ${PWD}:/usr/src --name=immuta-db-dev --add-host=service.immuta:10.0.2.2 -it immuta-db-dev
        # docker run -d --cap-add=SYS_PTRACE --cap-add=SYS_TIME --security-opt seccomp=unconfined -e IMMUTA_REMOTE_QUERY=true -p 5432:5432 -p 9091:9091 -v $PWD:/usr/src -v $BODATA_DIR:/bodata --name=immuta-db-dev --add-host=service.immuta:10.0.2.2 -it immuta-db-dev
        docker run -d --cap-add=SYS_PTRACE --cap-add=SYS_TIME --security-opt seccomp=unconfined -e IMMUTA_REMOTE_QUERY=true -p 5432:5432 -v {$PWD}:/usr/src --name=immuta-db-dev --add-host=service.immuta:10.0.2.2 $argv -it immuta-db-dev
        popd
        # docker run -d -p 5432:5432 -v ${PWD}:/src --name=immuta-db-dev -e IMMUTA_REMOTE_QUERY=true --add-host=service.immuta:10.0.2.2 -it immuta-db-dev 
        #docker run -d -p 5432:5432 -v ${PWD}:/src --name=immuta-db-dev --add-host=service.immuta:10.0.2.2 -it immuta-db-dev 
    end
end