function killPg
    dockerStop bodata_postgres
    dockerStop immuta-db-dev
end