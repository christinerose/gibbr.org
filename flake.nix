{
  description = "A flake for building https://gibbr.org";

  outputs = { self, nixpkgs }: {

    defaultPackage.x86_64-linux =
      with import nixpkgs { system = "x86_64-linux"; };
      stdenv.mkDerivation {
        name = "gibbr.org";

        src = self;

        buildInputs = [
          rsync
          pandoc
          perl
        ];

        installPhase = ''
          mkdir -p $out
          rsync -a --exclude '*.md' --exclude 'result' --exclude '.*' . $out
        '';
      };

  };
}
