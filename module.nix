{config, pkgs, options, lib, ...}:
let
  scream_receiver_unix_overlay = (import ./overlay.nix);
  cfg = config.services.scream-receiver;
in
{
  options.services.scream-receiver = {
    enable = lib.mkEnableOption "Scream audio receiver";
    interfaces = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = [ "eth0" ];
      description =
        ''
          The interfaces for which to perform NAT. Packets coming from
          these interface and destined for the external interface will
          be rewritten.
        '';
    };
    port = lib.mkOption {
      type = lib.types.int;
      default = 4010;
      example = 4010;
      description = ''
        Port number, which scream should listen to
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [ scream_receiver_unix_overlay ];
    environment.systemPackages = with pkgs; [
      scream-receiver-unix
    ];
    hardware.pulseaudio = {
      enable = true;
      systemWide = true;
      # allow root to access users's PA session
      extraConfig = ''
        load-module module-native-protocol-unix auth-anonymous=1 socket=/tmp/scream-pulse-socket
      '';
    };
    networking.firewall.interfaces =
      let
        fw_interface = item: {
          ${item} = {
            allowedUDPPorts = [
              cfg.port
            ];
          };
        };
        interfaces = lib.foldl' (acc: item: acc // (fw_interface item)) {} cfg.interfaces;
      in
        interfaces;
    systemd.services =
      let
        service_template = interface_name:
        let
          service_name = "scream-receiver-${interface_name}";
        in
        {
          ${service_name} = {
            description = "Scream audio receiver for interface ${interface_name}";
            wantedBy = [ "multi-user.target" ];
            after = [ "network.target" "pulseaudio.service" ];
            requires = [ "pulseaudio.service" ];
            path = with pkgs; [ scream-receiver-unix ];
            script = ''
                PULSE_SERVER=/tmp/scream-pulse-socket scream -p ${toString cfg.port} -i ${interface_name}
            '';
            serviceConfig = {
              Type = "simple";
              Restart = "always";
            };
          };
        };
        services = lib.foldl' (acc: item: acc // (service_template item) ) {} cfg.interfaces;
      in
        services;
  };
}