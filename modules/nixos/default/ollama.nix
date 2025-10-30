{
  lib,
  config,
  ...
}: let
  cfg = config.services.ollama;
in {
  config = lib.mkIf cfg.enable {
    # Enable ollama
    services.ollama = {
      acceleration = "cuda";
      loadModels = ["llama3.2:3b" "deepseek-r1:1.5b"];
      environmentVariables = {
        OLLAMA_ORIGINS = "*";
      };
    };

    services.open-webui = {
      enable = true;
    };
  };
}
