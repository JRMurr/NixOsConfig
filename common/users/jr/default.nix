{ ... }: {
  imports = [ ../../homemanager ];
  # Everything is this file will be under home-manager.users.<name>
  # https://rycee.gitlab.io/home-manager/options.html

  xdg.enable = true;
}
