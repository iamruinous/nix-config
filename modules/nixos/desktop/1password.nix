# programs._1password.enable = true;
{
  config,
  lib,
  ...
}: let
  cfg = config.programs._1password;
in {
  config = lib.mkIf cfg.enable {
    # Enable the 1Password CLI, this also enables a SGUID wrapper so the CLI can authorize against the GUI app
    # programs._1password = {
    #   enable = lib.mkDefault true;
    # };

    # Enable the 1Password GUI with myself as an authorized user for polkit
    programs._1password-gui = {
      enable = lib.mkDefault true;
      polkitPolicyOwners = ["jmeskill"]; # TODO: generalize user
    };
  };
}
