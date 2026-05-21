{ inputs, ... }:
{
  imports = [ (inputs.files + "/flake-module.nix") ];

  config.perSystem =
    { pkgs, ... }:
    {
      config = {
        files.files = [
          {
            path = "LICENSE";
            drv = pkgs.runCommand "LICENSE" { } ''
              cp ${./agpl-3.0.txt} $out
            '';
          }
        ];
      };
    };
}
