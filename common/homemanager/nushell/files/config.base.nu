$env.config = {
    show_banner: false,
}

source ~/.config/nushell/completion.nu


mut current = (($env | default {} config).config | default {} completions)
$current.completions = ($current.completions | default {} external)
$current.completions.external = {
    enable: true
    completer: $external_completer
}


$env.config = $current