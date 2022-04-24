function buildFinger
    docker stop immuta-fingerprint
    docker rm immuta-fingerprint
    pushd $FINGERPRINT_DIR
    make immuta-fingerprint
    docker run \
        --detach \
        --publish 5001:5001 \
        --name=immuta-fingerprint \
        --add-host=db.immuta:10.0.2.2 \
        immuta-fingerprint
    popd
    docker logs -f immuta-fingerprint
end