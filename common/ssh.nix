{
  # https://www.reddit.com/r/NixOS/comments/lsbo9a/people_using_sshagent_how_do_you_unlock_it_on/?context=3
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.lightdm.enableGnomeKeyring = true;
  # programs.ssh.startAgent = true;
}
