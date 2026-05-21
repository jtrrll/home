{ inputs, ... }:
{
  imports = [ inputs.treefmt-nix.flakeModule ];

  config.perSystem =
    { config, ... }:
    {
      config = {
        devenv.modules = [
          {
            git-hooks.hooks.treefmt = {
              enable = true;
              package = config.treefmt.build.wrapper;
            };
          }
        ];
        treefmt = {
          programs = {
            actionlint.enable = true;
            deadnix.enable = true;
            keep-sorted.enable = true;
            nixfmt.enable = true;
            shellcheck = {
              enable = true;
              excludes = [ ".envrc" ];
            };
            shfmt.enable = true;
            statix.enable = true;
            yamlfmt.enable = true;
          };
        };
      };
    };
}
