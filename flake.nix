{
  description = "I do not have to explain myself";

  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.xz";
    nixos-hardware.url = "github:NixOS/nixos-hardware";

    lix-module = {
      url = "https://git.lix.systems/lix-project/nixos-module/archive/main.tar.gz";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        lix = {
          url = "https://git.lix.systems/lix-project/lix/archive/main.tar.gz";
          flake = false;
        };
      };
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.rust-overlay.follows = "rust-overlay";
    };

    colmena = {
      url = "github:zhaofengli/colmena";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    catppuccin.url = "github:catppuccin/nix";
    catppuccin-palette = {
      url = "github:catppuccin/palette";
      flake = false;
    };

    linux-hardened.url = "git+https://woof.rip/mikael/linux-hardened.git";
    firefox.url = "git+https://woof.rip/mikael/firefox.git";

    nix-index-database = {
      url = "github:illdefined/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mpv-rtkit = {
      url = "git+https://woof.rip/mikael/mpv-rtkit.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    iosevka.url = "https://woof.rip/mikael/iosevka/archive/main.tar.gz";
  };

  nixConfig = {
    allow-import-form-derivation = true;

    extra-experimental-features = [ "pipe-operator" ];

    extra-substituters = [
      "https://cache.kyouma.net"
      "https://colmena.cachix.org"
      "https://catppuccin.cachix.org"
      "https://nix-community.cachix.org"
      "https://cache.lix.systems"
    ];

    extra-trusted-public-keys = [
      "cache.kyouma.net:Frjwu4q1rnwE/MnSTmX9yx86GNA/z3p/oElGvucLiZg="
      "colmena.cachix.org-1:7BzpDnjjH8ki2CT3f6GdOk7QAzPOl+1t3LvTLXqYcSg="
      "catppuccin.cachix.org-1:noG/4HkbhJb+lUAdKrph6LaozJvAeEEZj4N732IysmU="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cache.lix.systems:aBnZUw8zA7H35Cz2RyKFVs3H4PlGTLawyY5KRbvJR8o="
    ];
  };

  outputs = { self, nixpkgs, ... }@inputs:
  let
    inherit (nixpkgs) lib;

    load = base: default: builtins.readDir base
      |> lib.filterAttrs (name: type: builtins.match "(regular|directory)" type != null)
      |> lib.mapAttrs' (name: type: {
          name = if type == "regular" then lib.removeSuffix ".nix" name else name;
          value =
            let path = if type == "directory" then "${name}/${default}.nix" else name;
            in import "${base}/${path}" inputs;
        });

    eachSystem = fun: lib.mapAttrs fun self.lib.platforms;
  in {
    lib = load ./lib "lib" // {
      inherit load;
    };

    overlays = load ./overlay "overlay";
    legacyPackages = eachSystem (system: platform:
      import nixpkgs {
        localSystem = builtins.currentSystem or platform;
        crossSystem = platform;
        overlays = [ self.overlays.default ];
        config.allowUnsupportedSystem = true;
      });

    packages = eachSystem (system: platform:
      let pkgs = self.legacyPackages.${system};
      in load ./package "package"
        |> lib.mapAttrs (name: pkg: self.legacyPackages.${system}.callPackage pkg { })
        |> lib.filterAttrs (name: pkg: lib.meta.availableOn platform pkg));

    nixosModules = load ./nixos/module "module";

    colmena = load ./nixos/config "configuration" // {
      meta = {
        nixpkgs = self.legacyPackages.x86_64-linux;
      };

      defaults = { name, config, ... }: {
        deployment = {
          allowLocalDeployment = true;
          targetHost = config.networking.fqdnOrHostName;
          targetUser = null;
        };
      };
    };

    nixosConfigurations =
      let hive = inputs.colmena.lib.makeHive self.outputs.colmena;
      in hive.nodes;

    homeModules = load ./home/module "module";
    homeConfigurations = load ./home/config "home";

    devShells = eachSystem (system: platform: load ./shell "shell"
      |> lib.mapAttrs (name: shell: self.legacyPackages.${system}.callPackage shell { })
      |> lib.filterAttrs (name: shell: lib.meta.availableOn platform shell));

    hydraJobs = {
      package = self.packages
      |> lib.foldlAttrs (jobs: system: packages: lib.recursiveUpdate jobs
        (lib.mapAttrs (name: package: { ${system} = package; }) packages)) { };

      shell = self.devShells
      |> lib.foldlAttrs (jobs: system: shells: lib.recursiveUpdate jobs
        (lib.mapAttrs (name: shell: { ${system} = shell; }) shells)) { };

      nixos = self.nixosConfigurations
      |> lib.mapAttrs (name: host: {
        ${host.pkgs.stdenv.hostPlatform.system} = host.config.system.build.toplevel;
      });
    };
  };
}
