{ config, lib, ... }: {
  options = with lib; {
    myOptions.containers.dataDir = mkOption {
      type = types.str;
      default = "/dockerData";
      description =
        "The root directory where all nixos managed docker containers will store data.\n        \n        make sure the `docker` group is an owner of that folder\n        ";
    };
  };
}
