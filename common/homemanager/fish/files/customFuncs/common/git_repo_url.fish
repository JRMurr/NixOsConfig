function git_repo_url --description "Get the HTTP URL of the current repo"
    git ls-remote --get-url origin | sed -E -e 's@git\@([^:]+):(.*)@https://\1/\2@' -e 's@\.git@@'
end