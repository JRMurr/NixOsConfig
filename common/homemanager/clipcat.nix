{ pkgs, lib, config, nixosConfig, ... }:
let
  gcfg = nixosConfig.myOptions.graphics;
  tomlFormat = pkgs.formats.toml { };
  clipCatPkg = pkgs.clipcat;

  mkConfigFile = fName: opts: {
    name = "clipcat/${fName}.toml";
    value = { source = tomlFormat.generate "${fName}.toml" opts; };
  };

  daemonConfig = {
    daemonize = false;
    max_history = 50;
    history_file_path = "${config.xdg.cacheHome}/clipcat/clipcatd/db";
    log_level = "INFO";

    monitor = {
      load_current = true;
      enable_clipboard = true;
      enable_primary = true;
    };

    grpc = {
      host = "127.0.0.1";
      port = 45045;
    };
  };

  ctlConfig = {
    server_host = "127.0.0.1";
    server_port = 45045;
    log_level = "INFO";
  };

  menuConfig = {
    server_host = "127.0.0.1";
    server_port = 45045;
    finder = "rofi";

    rofi = {
      line_length = 100;
      menu_length = 30;
    };

    # [dmenu]
    # line_length = 100
    # menu_length = 30

    # [custom_finder]
    # program = 'fzf'
    # args = []
  };

in {
  config = lib.mkIf gcfg.enable {
    home.packages = [ clipCatPkg ];

    systemd.user.services.clipcat = {
      Unit = {
        Description = "clipcat daemon";
        After = [ "graphical-session.target" ];
      };
      Service = { ExecStart = "${clipCatPkg}/bin/clipcatd --no-daemon"; };
      Install = { WantedBy = [ "graphical-session.target" ]; };
    };

    xdg.configFile = lib.listToAttrs [
      (mkConfigFile "clipcatd" daemonConfig)
      (mkConfigFile "clipcatctl" ctlConfig)
      (mkConfigFile "clipcat-menu" menuConfig)
    ];

  };
}
