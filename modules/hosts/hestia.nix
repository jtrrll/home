{
  config,
  inputs,
  lib,
  ...
}:
{
  config.flake.nixosConfigurations.hestia = inputs.nixpkgs-nixos.lib.nixosSystem {
    modules =
      let
        dns = {
          services.adguardhome = {
            enable = true;
            settings = {
              dns = {
                upstream_dns = [
                  # keep-sorted start numeric=yes
                  "1.0.0.1" # Cloudflare
                  "1.1.1.1" # Cloudflare
                  "8.8.4.4" # Google
                  "8.8.8.8" # Google
                  # keep-sorted end
                ];
              };
              filtering = {
                protection_enabled = true;
                filtering_enabled = true;
              };
              filters = [
                {
                  enabled = true;
                  url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt";
                  name = "AdGuard DNS filter";
                  id = 1;
                }
                {
                  enabled = true;
                  url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_2.txt";
                  name = "AdAway Default Blocklist";
                  id = 2;
                }
              ];
            };
          };

          networking.firewall.allowedUDPPorts = [ 53 ];
          networking.firewall.allowedTCPPorts = [ 53 ];
        };
        homeAutomation = {
          services.home-assistant = {
            enable = true;
            config = {
              homeassistant = {
                name = "Home";
                unit_system = "metric";
              };
              http = {
                use_x_forwarded_for = true;
                trusted_proxies = [ "127.0.0.1" ];
              };
              default_config = { };
            };
          };
        };
        reverseProxy =
          {
            config,
            ...
          }:
          {
            services.caddy = {
              enable = true;
              openFirewall = true;
              virtualHosts.":80".extraConfig = ''
                handle_path /dns/* {
                  reverse_proxy localhost:${toString config.services.adguardhome.port}
                }
                handle_path /home/* {
                  reverse_proxy localhost:${toString config.services.home-assistant.config.http.server_port}
                }
              '';
            };
          };
      in
      lib.attrValues config.flake.nixosModules
      ++ [
        inputs.determinate.nixosModules.default
        # TODO: Re-enable once kernel build issue is resolved
        # inputs.nixos-hardware.nixosModules.raspberry-pi-3
        inputs.sops-nix.nixosModules.sops
        dns
        homeAutomation
        reverseProxy
        (
          _:
          {
            networking.hostName = "hestia";
            nixpkgs.hostPlatform = "aarch64-linux";

            # Filesystem declarations matching the official NixOS SD image layout
            fileSystems."/" = {
              device = "/dev/disk/by-label/NIXOS_SD";
              fsType = "ext4";
            };
            fileSystems."/boot/firmware" = {
              device = "/dev/disk/by-label/FIRMWARE";
              fsType = "vfat";
            };

            # NOTE: For initial nixos-anywhere install, temporarily replace the
            # sops + secretsFile config below with:
            #   networking.wireless.networks.herman_house.psk = "your_wifi_password";
            # After install, get the new host key:
            #   ssh-keyscan 10.0.0.2 | grep ed25519 | ssh-to-age
            # Update .sops.yaml, create secrets file with `sops`, then restore this config.
            # sops = {
            #   defaultSopsFile = ./hestia_secrets.yaml;
            #   age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
            #   secrets.wireless = { };
            # };

            networking = {
              useDHCP = false;
              wireless = {
                enable = true;
                # secretsFile = config.sops.secrets.wireless.path;
                # networks.herman_house.pskRaw = "ext:psk_home";
              };
              interfaces.wlan0 = {
                ipv4.addresses = [
                  {
                    address = "10.0.0.2";
                    prefixLength = 24;
                  }
                ];
              };
              defaultGateway = "10.0.0.1";
              nameservers = [ "127.0.0.1" ];
            };

            boot.loader = {
              grub.enable = false;
              generic-extlinux-compatible.enable = true;
            };

            services.openssh = {
              enable = true;
              settings = {
                PasswordAuthentication = false;
                KbdInteractiveAuthentication = false;
                PermitRootLogin = "yes";
              };
            };

            adminUser.enable = true;

            system.stateVersion = "25.05";
          }
        )
      ];
  };
}
