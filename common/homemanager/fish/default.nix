{
  pkgs,
  lib,
  osConfig,
  ...
}:
let
  isGraphical = osConfig.myOptions.graphics.enable;

  customPlugins = [
    {
      name = "fish-completion-sync";
      src = pkgs.fetchFromGitHub {
        owner = "pfgray";
        repo = "fish-completion-sync";
        rev = "ba70b6457228af520751eab48430b1b995e3e0e2";
        hash = "sha256-JdOLsZZ1VFRv7zA2i/QEZ1eovOym/Wccn0SJyhiP9hI=";
      };
    }
    {
      name = "fish-systemd";
      src = pkgs.fetchFromGitHub {
        owner = "wawa19933";
        repo = "fish-systemd";
        rev = "4e922a28ae183e0ddb28c35b8f1415d2c63f978d";
        hash = "sha256-km6VgvYO1b3wnmpKrnJUaZUrQiIDl8NetECa33jbLbo=";
      };
    }
  ];
  preBuiltPlugins = with pkgs.fishPlugins; [
    bass
    done
  ];

in
{
  home.sessionVariables = {
    VISUAL = "vim";
    EDITOR = if isGraphical then "code" else "vim";
  }
  // lib.optionalAttrs isGraphical {
    BROWSER = "firefox";
  };

  programs.fish = {
    enable = true;

    interactiveShellInit = ''
      set -g fish_greeting
    '';

    shellAliases = {
      cat = "bat -p --paging=never";
      cleanGit = "git branch --merged | egrep -v '(^\\*|master|dev)' | xargs git branch -d";
      cleanSquash = "git-delete-squashed";
      gitSyncUp = "git fetch upstream; git rebase upstream/master";
      lzd = "lazydocker";
      ls = "exa --icons";
      nbf = "nix build -L --file";
      nixRe = "nh os switch";
    };

    functions = {
      nobf = {
        wraps = "nix build -L --file";
        description = "nom build -L --file";
        body = "nom build -L --file $argv";
      };
      c = {
        argumentNames = [ "filename" ];
        description = "open editor alias";
        body = ''
          if test -n "$filename"
              $EDITOR $filename
          else
              $EDITOR $PWD
          end
        '';
      };
      wipeAllNode = ''
        find . -name "node_modules" -type d -prune -exec rm -rf '{}' +
      '';
      dockerStop = {
        wraps = "docker rm";
        body = ''
          docker stop $argv
          docker rm $argv
        '';
      };
      encodeFileToClip = {
        description = "base64 encodes the specified file and adds it to the clipboard";
        body = "base64 $argv | xclip -selection clipboard";
      };
      git_repo_url = {
        description = "Get the HTTP URL of the current repo";
        body = ''
          git ls-remote --get-url origin | sed -E -e 's@git\@([^:]+):(.*)@https://\1/\2@' -e 's@\.git@@'
        '';
      };
      nixDeploy = {
        wraps = "deploy";
        body = "deploy /etc/nixos $argv";
      };
      read_confirm = {
        description = "Ask the user for confirmation";
        argumentNames = [ "prompt" ];
        body = ''
          if test -z "$prompt"
              set prompt "Continue?"
          end
          while true
              read -p 'set_color green; echo -n "$prompt [y/N]: "; set_color normal' -l confirm
              switch $confirm
                  case Y y
                      return 0
                  case "" N n
                      return 1
              end
          end
        '';
      };
      cleanDocker = ''
        if read_confirm "Do you want to stop and remove all containers?"
            if docker ps -a -q | count > /dev/null
                docker stop (docker ps -a -q)
                docker rm (docker ps -a -q)
            end
        end
      '';
      dUp = {
        wraps = "docker-compose up";
        body = "docker-compose up $argv";
      };
      dDown = {
        wraps = "docker-compose down";
        body = "docker-compose down $argv";
      };
    };

    plugins = customPlugins;
  };

  home.packages =
    with pkgs;
    [
      killall
      jq
      libnotify
    ]
    ++ preBuiltPlugins;

  xdg.configFile."fish/fish_plugins".source = ./files/fish_plugins;
  xdg.configFile."fish/completions/nix.fish".source =
    "${pkgs.nix}/share/fish/vendor_completions.d/nix.fish";
}
