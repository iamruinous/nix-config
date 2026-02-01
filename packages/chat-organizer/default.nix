{pkgs, ...}:
let
  name = "chat-organizer";
  version = "0.1.0";
in
pkgs.writers.writePython3Bin name {
  libraries = []; # No external libraries needed
  flakeIgnore = ["E501"]; # Ignore line length warnings
} (builtins.readFile ./src/chat-organizer.py)
