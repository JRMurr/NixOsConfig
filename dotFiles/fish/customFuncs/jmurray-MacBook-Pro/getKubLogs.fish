function getKubLogs
    argparse p/partner -- $argv
    or return # exit if argparse failed because it found an option it didn't recognize - it will print an error
    set -l context 'kube-1.dev-test.immuta.io:jmurray'
    set -l pattern $argv[1]
    set -l logDir '/tmp/kubeLogs'
    if set -q _flag_partner
        set context 'kube-1.partner.immuta.com:jmurray'
    end
    set -l pods (kubectl -n iim --context $context get pods | grep $pattern | awk '{ print $1 }')
    if [ "$pods" ] && read_confirm "Do you want to get logs for: $pods"
        # wipe tmp dir if it exists
        if test -d "$logDir"
            rm -rf "$logDir"
        end
        mkdir "$logDir"
        for pod in (string split ' ' $pods)
            kubectl -n iim --context $context logs $pod > "$logDir/$pod.log"
        end
        echo "logs are in $logDir"
    end
end