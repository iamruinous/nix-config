{pkgs, ...}:
let
  name = "chat-organizer";
  version = "0.1.0";
in
pkgs.writers.writePython3Bin name {
  libraries = []; # No external libraries needed
  flakeIgnore = [
    "E501"  # Ignore line length warnings
    "W503"  # Ignore line break before binary operator (PEP8 changed preference)
    "E722"  # Ignore bare except (acceptable for JSON parsing)
    "F841"  # Ignore unused variables (false positives)
  ];
} (builtins.readFile ./src/chat-organizer.py)
