function encodeFileToClip --description "base64 encodes the specifed file and adds it to the clipboard"
    # primary and clipboard are weird https://wiki.archlinux.org/title/Clipboard
    # clipboard is where CTRL+V works
    # TODO: get a clipboard manager to sync
    base64 $argv | xclip -selection clipboard
end