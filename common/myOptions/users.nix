{ config, lib, ... }: {
  options = with lib; {
    myOptions.users = {
      makeJr = mkOption {
        default = true;
        example = true;
        description =
          "Make the jr account, if disabled jr will need to exist somehow";
        type = lib.types.bool;
      };

      jrAutoLogin = mkOption {
        default = true;
        example = true;
        description =
          "if jr will be the autologin";
        type = lib.types.bool;
      };
    };
  };
}
