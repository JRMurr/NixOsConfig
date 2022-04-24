function restartPg --wraps="docker run"
    dockerStop bodata_postgres
    # -e PG_LOG_MIN_MESSAGES=debug1
    docker run -d -p 5432:5432 --name=bodata_postgres --add-host=service.immuta:10.0.2.2 -e IMMUTA_REMOTE_QUERY=true $argv -i -t immuta-db 
    docker logs -f bodata_postgres
end