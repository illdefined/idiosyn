{ ... }: { lib, config, pkgs, ... }: {
  environment.etc."alsa-card-profile/profile-sets/fireface-ucx-2.conf".text = ''
    [General]
    auto-profiles = no

  '' + ({
    multichannel-input = {
      channels = [ ];
      direction = "input";
    };

    multichannel-output = {
      channels = [ ];
      direction = "output";
    };

    analog-mono = {
      channels = [ "mono" ];
      direction = "input";
    };

    analog-stereo = {
      channels = [ "front-left" "front-right" ];
      direction = "output";
    };

    analog-surround-40 = {
      channels = [ "front-left" "front-right" "rear-left" "rear-right" ];
      direction = "output";
    };
  } |> lib.mapAttrsToList (n: m: ''
    [Mapping ${n}]
    device-strings = hw:%f,0,0
    channel-map = ${m.channels ++ (lib.range (builtins.length m.channels) 19 |> map (i: "aux" + toString i)) |> lib.concatStringsSep ","}
    direction = ${m.direction}
  '') |> lib.concatLines) + ([
    {
      input = "analog-mono";
      output = "analog-stereo";
    }
    {
      input = "analog-mono";
      output = "analog-surround-40";
    }
    {
      input = "multichannel-input";
      output = "multichannel-output";
    }
  ] |> lib.imap0 (i: p: ''
    [Profile output:${p.output}+input:${p.input}]
    output-mappings = ${p.output}
    input-mappings = ${p.input}
    priority = ${100 - i |> toString}
    skip-probe = yes
  '') |> lib.concatLines);

  services.pipewire.wireplumber.extraConfig = {
    "fireface-ucx-2" = {
      "monitor.alsa.rules" = [
        {
          matches = [ {
            "device.bus" = "usb";
            "device.vendor.id" = "0x2a39";
            "device.product.id" = "0x3fd9";
          } ];

          actions.update-props = {
            "device.profile-set" = "fireface-ucx-2.conf";
          };
        }
        {
          matches = [ { "node.name" = "~alsa_(input|output).usb-RME_Fireface_UCX_II.*"; } ];
          actions.update-props = {
            "api.alsa.htimestamp" = true;
            "session.suspend-timeout-seconds" = 0;
          };
        }
      ];
    };
  };
}
