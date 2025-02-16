{ ... }: { lib, config, pkgs, ... }: {
  services.pipewire.wireplumber.extraConfig = {
    "fireface-ucx-2" = {
      "monitor.alsa.rules" = [
        {
          matches = [ { "node.name" = "~alsa_(input|output).usb-RME_Fireface_UCX_II.*"; } ];
          actions.update-props = {
            "api.alsa.htimestamp" = true;
            "api.alsa.headroom" = 64;
            "session.suspend-timeout-seconds" = 0;
          };
        }
        {
          matches = [ { "node.name" = "~alsa_input.usb-RME_Fireface_UCX_II.*"; } ];
          actions.update-props = {
            "latency.internal.rate" = 6; # 5.8
          };
        }
        {
          matches = [ { "node.name" = "~alsa_output.usb-RME_Fireface_UCX_II.*"; } ];
          actions.update-props = {
            "latency.internal.rate" = 5; # 5 for ≤ 96 kHz, 6 for > 96 kHz
          };
        }
      ];
    };
  };
}
