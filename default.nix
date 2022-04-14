{ pkgs ? import <nixpkgs> {  } }:
 
pkgs.stdenv.mkDerivation {
  name = "gibbr.org";

  src = ./.;

  buildInputs = with pkgs; [
    rsync
    pandoc
  ];

  installPhase = ''
    mkdir -p $out
    rsync -a --exclude '*.md' --exclude 'result' . $out
  '';
}
