{
  description = "A flake for building https://gibbr.org";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let pkgs = nixpkgs.legacyPackages.${system}; in
        {
          defaultPackage = pkgs.stdenv.mkDerivation {
            name = "gibbr.org";

            src = self;

            buildInputs = [
              pkgs.rsync
              pkgs.pandoc
            ];

            installPhase = ''
              mkdir -p $out
              rsync -a --exclude '*.md' --exclude 'result' --exclude '.*' . $out
            '';
          };
          devShells.default = pkgs.mkShell {
              buildInputs = [
                pkgs.pandoc
              ];
          };
        }
      );
}
