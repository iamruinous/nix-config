{
  lib,
  config,
  pkgs,
  ...
}:
with lib; let
  cfg = config.ruinous.git;

  # Default values
  defaultKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL8rjXP/sjewv6kM1aTtNWkVZKJpZvIAXIRqL81IyEsm";
  defaultEmail = "iamruinous@ruinous.social";
  defaultName = "Jade Meskill";

  # SSH signing program based on 1Password setting
  sshSignProgram =
    if cfg.signing.use1Password
    then "op-ssh-sign"
    else "${pkgs.openssh}/bin/ssh-keygen";

  # Profile submodule - defines options for each git profile
  profileOpts = {name, ...}: {
    options = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to enable this git profile.";
      };

      condition = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Git conditional include pattern (e.g., "gitdir/i:~/Projects/work/").
          If null, derived from the profile name as "gitdir/i:<name>/".
        '';
        example = "gitdir/i:~/Projects/github/";
      };

      userName = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Git user name for this profile. If null, uses default.";
        example = "Jade Meskill";
      };

      userEmail = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Git user email for this profile. If null, uses default.";
        example = "jade@example.com";
      };

      signingKey = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "SSH signing key for this profile. If null, uses default.";
        example = "ssh-ed25519 AAAA...";
      };

      signingFormat = mkOption {
        type = types.enum ["ssh" "openpgp" "x509"];
        default = "ssh";
        description = "Signing format for commits and tags.";
      };

      signer = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Override signing program for this profile.
          If null, uses the global setting based on use1Password.
        '';
      };

      extraConfig = mkOption {
        type = types.attrs;
        default = {};
        description = "Extra git config options for this profile.";
        example = {
          core.autocrlf = "input";
        };
      };
    };
  };

  # Generate gitdir condition from profile name if not explicitly set
  getCondition = name: profile:
    if profile.condition != null
    then profile.condition
    else "gitdir/i:${name}/";

  # Generate include entry for a profile
  mkInclude = name: profile: {
    condition = getCondition name profile;
    contents =
      {
        user = {
          name =
            if profile.userName != null
            then profile.userName
            else cfg.default.userName;
          email =
            if profile.userEmail != null
            then profile.userEmail
            else cfg.default.userEmail;
          signingkey =
            if profile.signingKey != null
            then profile.signingKey
            else cfg.default.signingKey;
        };
        gpg = {
          format = profile.signingFormat;
          ssh.program =
            if profile.signer != null
            then profile.signer
            else sshSignProgram;
        };
      }
      // profile.extraConfig;
  };

  # Filter enabled profiles and generate includes
  enabledProfiles = filterAttrs (_: p: p.enable) cfg.profiles;
  profileIncludes = mapAttrsToList mkInclude enabledProfiles;
in {
  options.ruinous.git = {
    signing = {
      use1Password = mkOption {
        type = types.bool;
        default = false;
        description = "Use 1Password for SSH signing (requires op-ssh-sign).";
      };
    };

    default = {
      userName = mkOption {
        type = types.str;
        default = defaultName;
        description = "Default git user name (used globally and as fallback for profiles).";
      };

      userEmail = mkOption {
        type = types.str;
        default = defaultEmail;
        description = "Default git user email (used globally and as fallback for profiles).";
      };

      signingKey = mkOption {
        type = types.str;
        default = defaultKey;
        description = "Default SSH signing key (used globally and as fallback for profiles).";
      };
    };

    profiles = mkOption {
      type = types.attrsOf (types.submodule profileOpts);
      default = {};
      description = ''
        Attribute set of git profiles for conditional includes.
        Each key becomes part of the gitdir condition pattern unless 'condition' is set.
        Profile options inherit from 'default' when set to null.
      '';
      example = literalExpression ''
        {
          # Match repos under ~/Projects/github/
          "~/Projects/github" = {
            userEmail = "jade@github.com";
          };
          # Match repos under ~/Projects/work/ with custom condition
          "work" = {
            condition = "gitdir/i:~/Projects/work/";
            userEmail = "jade@company.com";
            signingKey = "/path/to/work/key";
          };
        }
      '';
    };

    allowedSigners = mkOption {
      type = types.listOf (types.submodule {
        options = {
          email = mkOption {
            type = types.str;
            description = "Email address for the signer.";
          };
          key = mkOption {
            type = types.str;
            description = "SSH public key.";
          };
        };
      });
      default = [
        {
          email = "iamruinous@ruinous.social";
          key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL8rjXP/sjewv6kM1aTtNWkVZKJpZvIAXIRqL81IyEsm";
        }
        {
          email = "jade@ruinous.ai";
          key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEOUbvhmSusPR35I4Su5pcfyLl1SU8gjc65Rcj6JcDi+";
        }
      ];
      description = "List of allowed signers for SSH signature verification.";
    };
  };

  config = {
    # Generate allowed_signers file from the list
    home.file.".ssh/allowed_signers".text =
      concatMapStringsSep "\n" (s: "${s.email} ${s.key}") cfg.allowedSigners;

    # Add difftastic for better structural diffs
    home.packages = [pkgs.difftastic];

    programs.lazygit = {
      enable = mkDefault true;
      settings = {
        gui = {
          nerdFontsVersion = "3";
        };
      };
    };

    programs.git = {
      enable = mkDefault true;
      lfs.enable = mkDefault true;

      signing = {
        signByDefault = mkDefault true;
        key = mkDefault cfg.default.signingKey;
        format = mkDefault "ssh";
        signer = mkDefault sshSignProgram;
      };

      # Profile-based conditional includes
      includes = profileIncludes;

      settings = {
        user = {
          name = cfg.default.userName;
          email = cfg.default.userEmail;
        };
        alias = {
          a = "add";
          c = "commit -v";
          co = "checkout";
          d = "diff";
          ds = "diff --staged";
          s = "status";
          crypt = "git-crypt";
          # Difftastic aliases for structural diffs
          # See: https://difftastic.wilfred.me.uk/git.html
          dft = "-c diff.external=difft diff";
          dlog = "-c diff.external=difft log -p --ext-diff";
          dshow = "-c diff.external=difft show --ext-diff";
        };
        tag.forceSignAnnotated = true;
        pull.rebase = false;
        fetch.prune = true;
        push.default = "tracking";
        merge.tool = "vim";
        # Difftastic as difftool (use with: git difftool)
        diff.tool = "difftastic";
        difftool.prompt = false;
        difftool.difftastic.cmd = ''difft "$LOCAL" "$REMOTE"'';
        pager.difftool = true;
        mergetool.prompt = false;
        status.submoduleSummary = true;
        diff.submodule = "log";
        branch.autosetupmerge = true;
        init.defaultBranch = "main";
        gpg.ssh.allowedSignersFile = "~/.ssh/allowed_signers";
      };
    };
  };
}
