{ ... }: { lib, pkgs, ... }: {
  boot.kernelParams = [
    "zram.num_devices=0"
  ];

  boot.kernel.sysctl = {
    "vm.page-cluster" = lib.mkDefault 0;
    "vm.swappiness" = lib.mkDefault 180;
    "vm.watermark_boost_factor" = lib.mkDefault 0;
    "vm.watermark_scale_factor" = lib.mkDefault 125;
  };

  systemd.services.zram-swap =
  let
    writeShell = { name, text, runtimeInputs ? [ ] }:
      pkgs.writeShellApplication { inherit name text runtimeInputs; } + "/bin/${name}";
  in {
    description = "Compressed in-memory swap space";

    wantedBy = [ "swap.target" ];
    unitConfig.DefaultDependencies = false;

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      RuntimeDirectory = "zram-swap";

      CapabilityBoundingSet = [ "CAP_DAC_OVERRIDE" "CAP_SYS_ADMIN" ];
      SystemCallFilter = [ "@system-service" "@swap" ];

      ExecStartPre = writeShell {
        name = "zram-swap-start-pre";
        runtimeInputs = with pkgs; [ coreutils getconf util-linux ];
        text = ''
          pages="$(getconf _PHYS_PAGES)"
          pagesize="$(getconf PAGESIZE)"

          dev="$(cat /sys/class/zram-control/hot_add)"
          echo "$dev" >"$RUNTIME_DIRECTORY/device"

          echo zstd >"/sys/block/zram$dev/comp_algorithm"
          echo "algo=zstd level=1" >"/sys/block/zram$dev/algorithm_params"
          echo "$((pages * pagesize * 3 / 2))" >"/sys/block/zram$dev/disksize"

          mkswap "/dev/zram$dev"
        '';
      };

      ExecStart = writeShell {
        name = "zram-swap-start";
        runtimeInputs = with pkgs; [ util-linux ];
        text = ''
          swapon --discard --priority 32767 "/dev/zram$(<"$RUNTIME_DIRECTORY/device")"
        '';
      };

      ExecStop = writeShell {
        name = "zram-swap-stop";
        runtimeInputs = with pkgs; [ util-linux ];
        text = ''
          swapoff "/dev/zram$(<"$RUNTIME_DIRECTORY/device")"
        '';
      };

      ExecStopPost = writeShell {
        name = "zram-swap-stop-post";
        runtimeInputs = with pkgs; [ coreutils ];
        text = ''
          test -s "$RUNTIME_DIRECTORY/device" || exit 0

          dev="$(<"$RUNTIME_DIRECTORY/device")"

          echo 1 >"/sys/block/zram$dev/reset"
          echo "$dev" >/sys/class/zram-control/hot_remove

          rm -f -- "$RUNTIME_DIRECTORY/device"
        '';
      };
    };
  };
}
