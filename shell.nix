with import <nixpkgs> {};
mkShell {
  buildInputs = [
    pandoc
  ];
}
