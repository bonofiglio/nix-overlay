{
  inputs = { nixpkgs.url = "github:NixOS/nixpkgs/master"; };
  outputs = { self, nixpkgs, ... }@inputs: { overlays.default = import ./overlay.nix; };
}
