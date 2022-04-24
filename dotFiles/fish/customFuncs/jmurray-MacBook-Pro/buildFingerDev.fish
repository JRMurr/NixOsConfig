function buildFingerDev
    argparse r/runOnly -- $argv
        or return # exit if argparse failed because it found an option it didn't recognize - it will print an error
    docker stop immuta-fingerprint
    docker rm immuta-fingerprint
    docker stop immuta-fingerprint-devel
    docker rm immuta-fingerprint-devel
    pushd $FINGERPRINT_DIR
    if not set -q _flag_runOnly
        make immuta-fingerprint-devel
    end
    echo "run 'poetry run immuta-fingerprint --log-level DEBUG' when u get in the container"
    docker run \
        -it \
        --publish 5001:5001 \
        --name=immuta-fingerprint-devel \
        --add-host=db.immuta:10.0.2.2 \
        -v "$PWD"/fingerprint:/opt/immuta/fingerprint/fingerprint \
        --entrypoint /bin/bash \
        immuta-fingerprint:latest-devel
    popd
end