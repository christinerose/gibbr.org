{ pkgs, config, lib, ... }:

let cfg = config.services."gibbr.org";
{
  options.services."gibbr.org".enable = lib.mkEnableOption "gibbr.org";

  config = lib.mkIf cfg.enable {
    services.nginx = {
      enable = true;
      virtualHosts."gibbr.org" = {
          forceSSL = true;
          enableACME = true;
          root = "${pkgs."gibbr.org"}";
          extraConfig = ''
          error_page 403 =404 /404.html;
          error_page 404 /404.html;
          '';
      };
      virtualHosts."www.gibbr.org" = {
        addSSL = true;
        useACMEHost = "gibbr.org";
        extraConfig = ''
          return 301 $scheme://gibbr.org$request_uri;
        '';
      };
      virtualHosts."_.gibbr.org" = {
        addSSL = true;
        useACMEHost = "gibbr.org";
        extraConfig = ''
          return 301 $scheme://gibbr.org$request_uri;
        '';
      };
    };

    security.acme = {
      defaults.email = "ryan@gibbr.org";
      acceptTerms = true;
      certs."gibbr.org".extraDomainNames = [ "www.gibbr.org" ];
    };
  };
}
