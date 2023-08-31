
# https://www.nushell.sh/cookbook/external_completers.html

source ~/.cache/carapace/init.nu

let carapace_completer = {|spans|
    carapace $spans.0 nushell $spans | from json
}

let fish_completer = {|spans|
    fish --command $'complete "--do-complete=($spans | str join " ")"'
    | $"value(char tab)description(char newline)" + $in
    | from tsv --flexible --no-infer
}

let zoxide_completer = {|spans|
    $spans | skip 1 | zoxide query -l $in | lines | where {|x| $x != $env.PWD}
}


# This completer will use carapace by default
let external_completer = {|spans|
    let expanded_alias = (scope aliases | where name == $spans.0 | get -i 0 | get -i expansion)
    let spans = (if $expanded_alias != null  {
        $spans | skip 1 | prepend ($expanded_alias | split words)
    } else { $spans })

    {
        # carapace completions are incorrect for nu
        nu: $fish_completer
        # fish completes commits and branch names in a nicer way
        git: $fish_completer
        hg: $fish_completer
        __zoxide_z: $zoxide_completer
        __zoxide_zi: $zoxide_completer
        z: $zoxide_completer
        zi: $zoxide_completer
    } | get -i $spans.0 | default $carapace_completer | do $in $spans

}
