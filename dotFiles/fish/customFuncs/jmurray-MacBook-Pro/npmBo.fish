function npmBo
    pushd "$BODATA_DIR/service"
    wipeAllNode
    npm install
    popd
end