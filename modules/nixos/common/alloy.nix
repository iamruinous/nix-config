# ruinous.alloy.journal.enable = true;
{config, ...}: let
  cfg = config.ruinous.alloy;
in {
  environment.etc."alloy/journal.alloy" = {
    enable = cfg.journal.enable;
    text = ''
      loki.relabel "journal" {
        forward_to = []
        rule {
          source_labels = ["__journal__systemd_unit"]
          target_label  = "unit"
        }
      }

      loki.source.journal "journalctl"  {
        forward_to    = [loki.write.main_loki.receiver]
        relabel_rules = loki.relabel.journal.rules
        labels        = {
          component = "loki.source.journal",
          instance = constants.hostname,
        }
      }

      loki.write "main_loki" {
         endpoint {
            url = "${cfg.loki.url}/loki/api/v1/push"
         }
      }
    '';
  };
}
