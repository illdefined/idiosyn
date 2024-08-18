{ ... }: { config, ...}: {
  hardware.bluetooth.enable = true;
  hardware.wirelessRegulatoryDatabase = true;
  networking.wireless.iwd = {
    enable = true;
    settings = {
      General = {
        AddressRandomization = "network";
      };

      Rank = {
        BandModifier2_4GHz = 0.8;
      };
    };
  };
}
