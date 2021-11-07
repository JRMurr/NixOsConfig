run `lorri init` in the desired folder, then `direnv allow`. More info https://github.com/nix-community/lorri

`setupLorri` fish func does the above


add
```
.envrc
shell.nix
```
to `<projectDir>/.git/info/exclude` to not track the files