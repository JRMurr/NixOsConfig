
# Nix templates

to use a template run
```
nix flake --refresh init --template github:JRMurr/NixOsConfig#<templateName>

# or to specify a dir
nix flake --refresh new --template github:JRMurr/NixOsConfig#<templateName> <pathToProjectDir>
```