$env.config = {
    show_banner: false,
}

source ~/.config/nushell/completion.nu


mut current = (($env | default {} config).config | default {} completions)
$current.completions = ($current.completions | default {} external)
$current.completions.external = ($current.completions.external 
    | default true enable
    | upsert completer $external_completer)


$env.config = $current