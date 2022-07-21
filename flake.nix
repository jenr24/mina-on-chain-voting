{
  description = "On Chain Signalling Deployment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/22.05";
    flake-utils.url = "github:numtide/flake-utils";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    deploy-rs.url = "github:serokell/deploy-rs";
    mina.url = "github:MinaProtocol/mina";
  };

  outputs = { self, nixpkgs, flake-utils, flake-compat, deploy-rs, mina }: 
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in rec {

        deploy.nodes.onChain-signalling = {
          hostname = "35.203.38.140";

          profiles = { };
        };

        checks = builtins.mapAttrs (system: 
          deployLib: deployLib.deployChecks self.deploy
        ) deploy-rs.lib;

        devShell = pkgs.mkShell {

          buildInputs = with pkgs; [
            haskell-language-server
            rnix-lsp nixpkgs-fmt
            geos
            gdal
            nixpkgs-fmt
            (python38.withPackages (ps: with ps; [ lxml pycurl certifi beautifulsoup4 ]))
            # postgres with postgis support
            (postgresql.withPackages (p: [ p.postgis ]))

            (haskellPackages.ghcWithPackages (self: with haskellPackages; [
              curl xml tar zlib fused-effects megaparsec bytestring directory tmp-postgres json
            ]))

            bun
          ];

          postgresConf =
            pkgs.writeText "postgresql.conf"
              ''
                # Add Custom Settings
                log_min_messages = warning
                log_min_error_statement = error
                log_min_duration_statement = 100  # ms
                log_connections = on
                log_disconnections = on
                log_duration = on
                #log_line_prefix = '[] '
                log_timezone = 'UTC'
                log_statement = 'all'
                log_directory = 'pg_log'
                log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'
                logging_collector = on
                log_min_error_statement = error
              '';

          PGDATA = "${toString ./.}/.pg";

          shellHook = ''
            runghc download_archive_dump.hs
          '';
        };
      }
    );
}