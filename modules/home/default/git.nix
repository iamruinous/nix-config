{ lib,
  config,
  ...
}: let
  git_config = ../../../files/configs/git;
  cfg = config.ruinous.git;

  # Default keys
  defaultGithubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGcg4sQO+hRaGrHLLU0pXl7tEZIQGkmwxiA9klN0p6h+ jade.meskill@gmail.com";
  defaultRuinousKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL8rjXP/sjewv6kM1aTtNWkVZKJpZvIAXIRqL81IyEsm";
  defaultMiscKey = "6AD7FC0814C30503";
in {
  options.ruinous.git = {
    signing = {
      github = lib.mkOption {
        type = lib.types.str;
        default = defaultGithubKey;
        description = "Signing key for GitHub";
      };
      farmforge = lib.mkOption {
        type = lib.types.str;
        default = defaultRuinousKey;
        description = "Signing key for Ruinous Social / FarmForge";
      };
      misc = lib.mkOption {
        type = lib.types.str;
        default = defaultMiscKey;
        description = "Signing key for Codeberg / Sourcehut";
      };
      miscFormat = lib.mkOption {
        type = lib.types.enum ["ssh" "openpgp"];
        default = "openpgp";
        description = "Signing format for Misc keys";
      };
    };
  };

  config = {
    home.file.".ssh/allowed_signers".text = ''
      iamruinous@ruinous.social ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL8rjXP/sjewv6kM1aTtNWkVZKJpZvIAXIRqL81IyEsm
      iamruinous@ruinous.social ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEOUbvhmSusPR35I4Su5pcfyLl1SU8gjc65Rcj6JcDi+
      jade.meskill@gmail.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGcg4sQO+hRaGrHLLU0pXl7tEZIQGkmwxiA9klN0p6h+ jade.meskill@gmail.com
      jade.meskill@gmail.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEOUbvhmSusPR35I4Su5pcfyLl1SU8gjc65Rcj6JcDi+
      codey@ruinous.ai ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEOUbvhmSusPR35I4Su5pcfyLl1SU8gjc65Rcj6JcDi+
    '';

    programs.lazygit = {
      enable = lib.mkDefault true;
      settings = {
        gui = {
          nerdFontsVersion = "3";
        };
      };
    };

    # Install git via home-manager module
    programs.git = {
      enable = lib.mkDefault true;
      lfs.enable = lib.mkDefault true;
      signing = {
        signByDefault = lib.mkDefault true;
      };
      includes = [
        {
          condition = "gitdir/i:codeberg\/iamruinous/";
          contents = {
            user = {
              name = "Jade Meskill";
              email = "iamruinous@ruinous.social";
              signingkey = cfg.signing.misc;
            };
            gpg =
              if cfg.signing.miscFormat == "ssh"
              then {
                format = "ssh";
                ssh.program = "op-ssh-sign";
              }
              else {
                format = "openpgp";
              };
          };
        }
        {
          condition = "gitdir/i:github\/iamruinous/";
          contents = {
            user = {
              name = "Jade Meskill";
              email = "jade.meskill@gmail.com";
              signingkey = cfg.signing.github;
            };
            gpg = {
              format = "ssh";
              ssh.program = "op-ssh-sign";
            };
          };
        }
        {
          condition = "gitdir/i:farmforge\/iamruinous/";
          contents = {
            user = {
              name = "Jade Meskill";
              email = "iamruinous@ruinous.social";
              signingkey = cfg.signing.farmforge;
            };
            gpg = {
              format = "ssh";
              ssh.program = "op-ssh-sign";
            };
          };
        }
        {
          condition = "gitdir/i:ruinous\.social\/iamruinous/";
          contents = {
            user = {
              name = "Jade Meskill";
              email = "iamruinous@ruinous.social";
              signingkey = cfg.signing.farmforge;
            };
            gpg = {
              format = "ssh";
              ssh.program = "op-ssh-sign";
            };
          };
        }
        {
          condition = "gitdir/i:sourcehut\/iamruinous/";
          contents = {
            user = {
              name = "Jade Meskill";
              email = "iamruinous@ruinous.social";
              signingkey = cfg.signing.misc;
            };
            gpg =
              if cfg.signing.miscFormat == "ssh"
              then {
                format = "ssh";
                ssh.program = "op-ssh-sign";
              }
              else {
                format = "openpgp";
              };
          };
        }
      ];
      settings = {
        aliases = {
          a = "add";
          c = "commit -v";
          co = "checkout";
          d = "diff";
          ds = "diff --staged";
          s = "status";
          crypt = "git-crypt";
        };
        tag.forceSignAnnotated = "true";
        pull.rebase = "false";
        fetch.prune = "true";
        push.default = "tracking";
        merge.tool = "vim";
        difftool.prompt = "false";
        mergetool.prompt = "false";
        status.submoduleSummary = "true";
        diff.submodule = "log";
        branch.autosetupmerge = "true";
        init.defaultBranch = "main";
        gpg.ssh.allowedSignersFile = "~/.ssh/allowed_signers";
        gpg.format = "ssh";
      };
    };

    xdg.configFile = {
      "git" = {
        source = "${git_config}";
        recursive = true;
      };
    };
  };
}
