{
  description = "giacenza-lynx — miso-native giacenza calculator Lynx bundle";

  nixConfig = {
    extra-substituters = [
      "https://haskell-miso-cachix.cachix.org"
    ];
    extra-trusted-public-keys = [
      "haskell-miso-cachix.cachix.org-1:m8hN1cvFMJtYib4tj+06xkKt5ABMSGfe8W7s40x1kQ0="
    ];
  };

  inputs.miso.url = "github:dmjio/miso";

  outputs = { self, miso }:
    let
      # Reuse miso's pinned nixpkgs so the native tooling shares one lock entry.
      nixpkgs = miso.inputs.nixpkgs;
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = f:
        builtins.listToAttrs
          (map (system: { name = system; value = f system; }) systems);
    in
    {
      # main.lynx.bundle + main.lynx.bundle.sha256, via miso's ghcNative
      # package set (GHCJS + -fnative miso) and mkLynxBundle (bun + rspeedy).
      packages = forAllSystems (system:
        let
          misoLib = miso.lib.${system};
          ghcNativeApp = misoLib.ghcNative.callCabal2nix "giacenza-lynx" ./. {
            miso = misoLib.ghcNative.miso-native;
          };
          bundle = misoLib.mkLynxBundle {
            name = "giacenza-lynx-bundle";
            jsDrv = ghcNativeApp;
            exeName = "giacenza-lynx";
            styles = ./styles.css;
          };
        in
        {
          giacenza-lynx-bundle = bundle;
          default = bundle;
        });

      # Native GHC shell: owns the domain library and the invariant proofs.
      # The miso app itself is only built by ghcNative (see packages).
      devShells = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          nativeGhc = pkgs.haskell.packages.ghc9122.ghcWithPackages (hp: [
            hp.hspec
            hp.QuickCheck
          ]);
        in
        {
          default = pkgs.mkShell {
            packages = [
              nativeGhc
              pkgs.cabal-install
              pkgs.just
              pkgs.hlint
              pkgs.fourmolu
            ];
          };
        });
    };
}
