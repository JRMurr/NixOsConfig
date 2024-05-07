{ lib, ... }: {
  # sudo fprintd-enroll user
  services.fprintd.enable = true;
  security.pam.services.login.fprintAuth = true;
  security.pam.services.xscreensaver.fprintAuth = true;

  services.displayManager = {
    # disable autologin
    autoLogin.enable = lib.mkForce false;
  };

}
