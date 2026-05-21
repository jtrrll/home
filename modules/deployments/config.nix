{ config, ... }:
{
  config.flake.deployments.local = [
    {
      nixosConfiguration = config.flake.nixosConfigurations.hestia;
      ipAddress = "10.0.0.2";
    }
  ];
}
