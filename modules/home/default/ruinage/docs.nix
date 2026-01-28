# Ruinage Documentation Aggregation
#
# This module provides:
# - Global documentation settings (ruinous.ruinage.docs.*)
# - Auto-discovery of flake inputs with 'docs' packages
# - Aggregated docs package served from Nix store (accessible by Caddy)
# - Index page generation listing all projects
#
# Architecture:
# - Automatically discovers flake inputs that have a 'docs' package output
# - Includes local nix-config docs from flake.packages.${system}.docs
# - A combined derivation symlinks all docs into one package
# - The package path is exposed for NixOS-level Caddy config
#
# Usage:
#   ruinous.ruinage.docs = {
#     enable = true;
#   };
#
# Then in NixOS Caddy config:
#   virtualHosts."docs.ruinage.ai".extraConfig = ''
#     root * ${config.home-manager.users.jmeskill.ruinous.ruinage.docs.package}
#     file_server
#   '';
{
  config,
  lib,
  pkgs,
  flake,
  ...
}:
with lib; let
  cfg = config.ruinous.ruinage;
  docsCfg = config.ruinous.ruinage.docs;

  # Get docs package for a project from flake inputs
  # Checks if the project name matches a flake input with a docs package
  getDocsPackageFromInput = projectName:
    if flake.inputs ? ${projectName} &&
       flake.inputs.${projectName} ? packages &&
       flake.inputs.${projectName}.packages ? ${pkgs.system} &&
       flake.inputs.${projectName}.packages.${pkgs.system} ? docs
    then flake.inputs.${projectName}.packages.${pkgs.system}.docs
    else null;

  # Get docs package from local flake packages (for nix-config itself)
  getLocalDocsPackage = projectName:
    if projectName == "nix-config" &&
       flake.packages ? ${pkgs.system} &&
       flake.packages.${pkgs.system} ? docs
    then flake.packages.${pkgs.system}.docs
    else null;

  # Get docs package for a project (tries flake input first, then local)
  getDocsPackage = projectName:
    let
      fromInput = getDocsPackageFromInput projectName;
      fromLocal = getLocalDocsPackage projectName;
    in
      if fromInput != null then fromInput
      else if fromLocal != null then fromLocal
      else null;

  # Get all project names from ruinage config
  allProjectNames = attrNames (cfg.projects or {});

  # Filter to projects that have docs packages available
  projectsWithDocs = filter (name: getDocsPackage name != null) allProjectNames;

  # Build attrset of { projectName = docsPackage; }
  allDocsPackages = listToAttrs (map (name: {
    inherit name;
    value = getDocsPackage name;
  }) projectsWithDocs);

  # Human-readable titles for known projects
  projectTitles = {
    "nix-config" = "NixOS Configuration";
    "ruinagents" = "Ruinous Agents";
    "budgey-assistant-ingest-tools" = "Budgey Ingest Tools";
    "budgey-assistant-dashboard" = "Budgey Assistant Dashboard";
    "n8n-agent" = "n8n Agent";
  };

  # Get title for a project (fallback to capitalized name)
  getTitle = name:
    projectTitles.${name} or (
      lib.concatMapStrings (s: lib.toUpper (lib.substring 0 1 s) + lib.substring 1 (-1) s)
        (lib.splitString "-" name)
    );

  # Generate index HTML page
  mkIndexHtml = let
    # Sort project names alphabetically
    sortedNames = lib.sort (a: b: a < b) (attrNames allDocsPackages);
    projectLinks = concatMapStringsSep "\n    " (name: let
      title = getTitle name;
      description = "Documentation for ${title}";
    in ''
      <li><a href="/${name}/">${title}</a> - ${description}</li>'') sortedNames;
  in ''
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Ruinage Documentation</title>
      <style>
        :root {
          --bg-color: #1a1a2e;
          --text-color: #eaeaea;
          --link-color: #4fc3f7;
          --link-hover: #81d4fa;
          --border-color: #333;
        }
        @media (prefers-color-scheme: light) {
          :root {
            --bg-color: #fafafa;
            --text-color: #333;
            --link-color: #0066cc;
            --link-hover: #0088ff;
            --border-color: #ddd;
          }
        }
        body {
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
          max-width: 800px;
          margin: 50px auto;
          padding: 0 20px;
          background-color: var(--bg-color);
          color: var(--text-color);
          line-height: 1.6;
        }
        h1 {
          border-bottom: 2px solid var(--border-color);
          padding-bottom: 10px;
          margin-bottom: 30px;
        }
        ul {
          list-style: none;
          padding: 0;
        }
        li {
          margin: 15px 0;
          padding: 10px;
          border-radius: 5px;
          transition: background-color 0.2s;
        }
        li:hover {
          background-color: rgba(128, 128, 128, 0.1);
        }
        a {
          color: var(--link-color);
          text-decoration: none;
          font-weight: 500;
        }
        a:hover {
          color: var(--link-hover);
          text-decoration: underline;
        }
        .footer {
          margin-top: 50px;
          padding-top: 20px;
          border-top: 1px solid var(--border-color);
          font-size: 0.9em;
          opacity: 0.7;
        }
      </style>
    </head>
    <body>
      <h1>Ruinage Documentation</h1>
      <ul>
        ${projectLinks}
      </ul>
      <div class="footer">
        <p>Generated by <a href="https://github.com/iamruinous/nix-config">ruinage</a></p>
      </div>
    </body>
    </html>
  '';

  # Generate index.html as a derivation
  indexHtml = pkgs.writeText "ruinage-docs-index.html" mkIndexHtml;

  # Create aggregated docs package with symlinks to all project docs
  # This package lives in the Nix store and is accessible by Caddy
  # Note: Symlinks preserve ETags from source packages
  aggregatedDocs = pkgs.runCommand "ruinage-docs-aggregated" {} ''
    mkdir -p $out

    # Copy index page (not symlink, so we can generate its ETag)
    cp ${indexHtml} $out/index.html

    # Generate ETag for index.html (RFC 7232 requires quoted hash)
    hash=$(${pkgs.coreutils}/bin/sha256sum $out/index.html | ${pkgs.coreutils}/bin/cut -d' ' -f1)
    echo "\"$hash\"" > $out/index.html.etag

    # Symlink each project's docs (preserves their ETags)
    ${concatMapStringsSep "\n" (name: let
      docsPackage = allDocsPackages.${name};
    in ''
      ln -s ${docsPackage} $out/${name}
    '') (attrNames allDocsPackages)}
  '';
in {
  options.ruinous.ruinage.docs = {
    enable = mkEnableOption "Documentation aggregation for ruinage projects";

    package = mkOption {
      type = types.package;
      readOnly = true;
      description = ''
        The aggregated documentation package. Use this path in Caddy config.
        This is a read-only option set automatically when docs.enable = true.
      '';
    };

    discoveredProjects = mkOption {
      type = types.listOf types.str;
      readOnly = true;
      description = ''
        List of project names with discovered docs packages.
        This is auto-populated from flake inputs that have a 'docs' package output.
      '';
    };

    caddy = {
      fqdn = mkOption {
        type = types.str;
        default = "docs.ruinage.ai";
        description = "FQDN for the documentation site (used by system-level Caddy config).";
        example = "docs.example.com";
      };

      port = mkOption {
        type = types.port;
        default = 8080;
        description = "Port for local documentation serving.";
      };
    };
  };

  config = mkIf docsCfg.enable {
    # Expose the aggregated docs package for use by NixOS Caddy config
    ruinous.ruinage.docs.package = aggregatedDocs;

    # Expose list of discovered docs for debugging/introspection
    ruinous.ruinage.docs.discoveredProjects = attrNames allDocsPackages;
  };
}
