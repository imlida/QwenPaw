{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  packages = [
    # 在此声明你需要的软件包
    # 例如:
    # pkgs.python311
    # pkgs.nodejs-18_x
    # pkgs.git
    # pkgs.tmux
    # pkgs.htop
  ];
  
  shellHook = ''
    echo "Nix environment loaded"
    echo "Available packages: $(nix-env -q)"
  '';
}
