function buildPost
    cd $BODATA_DIR
    kitty @ set-tab-title "POSTGRES"
    if read_confirm "Do you want to stop and rebuild the pg container?"
        killPg
        docker compose down --volumes
        docker compose up --build --detach
    else
        docker compose up --detach
    end

    cd service
    # npx prisma migrate dev
    # if not make db VISIBILITY=internal MAKE_JOBS=4
    #     popd
    #     return 1
    # end
    #  -e PG_LOG_MIN_MESSAGES=debug1
    # docker run --rm -d -p 5432:5432 --name=bodata_postgres --add-host=service.immuta:10.0.2.2 \
    #     -e IMMUTA_REMOTE_QUERY=true -e SUPERUSER_ADDRESS="0.0.0.0/0" -e PG_LOG_MIN_MESSAGES="LOG" \
    #     # -e IMMUTA_CREATE_AUDIT_USER=true \
    #     # -e IMMUTA_FEATURE_AUDIT_SCHEMA=true \
    #      -e IMMUTA_FEATURE_PRISMA_MIGRATE=true \
    #     $argv -i -t immuta-db
    # docker logs -f bodata_postgres
    docker compose logs --follow
end
