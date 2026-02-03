{ lib, ... }:
{
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    enableBashIntegration = true;
    # enableTransience = true;
    settings = {
      # stolen from https://draculatheme.com/starship dont think its needed
      # aws.style = "bold #ffb86c";
      # cmd_duration.style = "bold #f1fa8c";
      # directory.style = "bold #50fa7b";
      # hostname.style = "bold #ff5555";
      # git_branch.style = "bold #ff79c6";
      # git_status.style = "bold #ff5555";
      # username = {
      #   format = "[$user]($style) on ";
      #   style_user = "bold #bd93f9";
      # };
      # character = {
      #   success_symbol = "[λ](bold #f8f8f2)";
      #   error_symbol = "[λ](bold #ff5555)";
      # };

      git_status = {
        stashed = "";
      };

      hg_branch = {
        disabled = false;
      };
      cmd_duration = {
        min_time = 500;
        show_milliseconds = true;
      };

      time = {
        disabled = false;
      };

      jobs.disabled = true;

      shell.disabled = false;
      # hostname.disabled = true;

      format =
        let
          # https://starship.rs/config/#prompt
          modules = [
            # displayed in order
            "shell" # moved this
            "username"
            "hostname"
            "localip"
            "shlvl"
            "singularity"
            "kubernetes"
            "directory"
            "vcsh"
            "fossil_branch"
            "git_branch"
            "git_commit"
            "git_state"
            "git_metrics"
            "git_status"
            "hg_branch"
            "pijul_channel"
            "docker_context"
            "package"
            "c"
            "cmake"
            "cobol"
            "daml"
            "dart"
            "deno"
            "dotnet"
            "elixir"
            "elm"
            "erlang"
            "fennel"
            "golang"
            "guix_shell"
            "haskell"
            "haxe"
            "helm"
            "java"
            "julia"
            "kotlin"
            "gradle"
            "lua"
            "nim"
            "nodejs"
            "ocaml"
            "opa"
            "perl"
            "php"
            "pulumi"
            "purescript"
            "python"
            "raku"
            "rlang"
            "red"
            "ruby"
            "rust"
            "scala"
            "solidity"
            "swift"
            "terraform"
            "vlang"
            "vagrant"
            "zig"
            "buf"
            "nix_shell"
            "conda"
            "meson"
            "spack"
            "memory_usage"
            "aws"
            # "gcloud"
            "openstack"
            "azure"
            "env_var"
            "crystal"
            "custom"
            "sudo"
            "time" # moved this
            "cmd_duration"
            "line_break"
            "jobs"
            "battery"
            # "time"
            "status"
            "os"
            "container"
            # "shell"
            "character"
          ];
        in
        lib.concatMapStrings (m: "$" + m) modules;

    };
  };
}
