{ pkgs, ... }: {
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    enableBashIntegration = true;
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

      hg_branch = { disabled = false; };
      cmd_duration = {
        min_time = 500;
        show_milliseconds = true;
      };
    };
  };
}
