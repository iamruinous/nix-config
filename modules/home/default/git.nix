{
  lib,
  config,
  ...
}: let
  cfg = config.ruinous.git;

  # Default keys
  defaultGithubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGcg4sQO+hRaGrHLLU0pXl7tEZIQGkmwxiA9klN0p6h+ jade.meskill@gmail.com";
  defaultRuinousKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL8rjXP/sjewv6kM1aTtNWkVZKJpZvIAXIRqL81IyEsm";
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
      codeberg = lib.mkOption {
        type = lib.types.str;
        default = defaultRuinousKey;
        description = "Signing key for Codeberg";
      };
      sourcehut = lib.mkOption {
        type = lib.types.str;
        default = defaultRuinousKey;
        description = "Signing key for Sourcehut";
      };
    };
    email = {
      github = lib.mkOption {
        type = lib.types.str;
        default = "jade.meskill@gmail.com";
        description = "Email for GitHub";
      };
      farmforge = lib.mkOption {
        type = lib.types.str;
        default = "iamruinous@ruinous.social";
        description = "Email for Ruinous Social / FarmForge";
      };
      codeberg = lib.mkOption {
        type = lib.types.str;
        default = "iamruinous@ruinous.social";
        description = "Email for Codeberg";
      };
      sourcehut = lib.mkOption {
        type = lib.types.str;
        default = "iamruinous@ruinous.social";
        description = "Email for Sourcehut";
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
              email = cfg.email.codeberg;
              signingkey = cfg.signing.codeberg;
            };
            gpg = {
              format = "ssh";
              ssh.program = "op-ssh-sign";
            };
          };
        }
        {
          condition = "gitdir/i:github\/iamruinous/";
          contents = {
            user = {
              name = "Jade Meskill";
              email = cfg.email.github;
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
              email = cfg.email.farmforge;
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
              email = cfg.email.farmforge;
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
              email = cfg.email.sourcehut;
              signingkey = cfg.signing.sourcehut;
            };
            gpg = {
              format = "ssh";
              ssh.program = "op-ssh-sign";
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
  };
}
