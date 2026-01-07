{
  lib,
  pkgs,
  home-manager-lib,
  ...
}:
let
  inherit (pkgs) jq;
in
home-manager-lib.runHomeManagerTestSuite {
  name = "opencode-module-test";

  extraSpecialArgs = {
    # This makes the argument available to any module evaluated by the test,
    # resolving the infinite recursion if blueprint auto-discovers this file.
    inherit home-manager-lib;
  };

  users.testuser = {
    imports = [ ./opencode.nix ];

    home.stateVersion = "24.05";

    ruinous.ai-cli.opencode = {
      enable = true;
      plugins = [ "my-test-plugin@v1.0.0" ];
      mcpServers = {
        "test-server" = {
          type = "remote";
          url = "http://test.dev/mcp";
        };
      };
    };

    # Make jq available to the test script
    home.packages = [ jq ];
  };

  testScript = ''
    # Wait for activation to complete
    ${pkgs.procps}/bin/pwait home-manager-generation

    # Path to the config file
    CONFIG_FILE="/home/testuser/.config/opencode/opencode.json"

    # --- Test Case 1: Initial Creation and Injection ---
    assert test -f "$CONFIG_FILE"

    # Check that default and custom plugins are present
    assert jq -e '.plugin | index("oh-my-opencode@v2.14.0")' "$CONFIG_FILE"
    assert jq -e '.plugin | index("my-test-plugin@v1.0.0")' "$CONFIG_FILE"

    # Check that default and custom MCP servers are present
    assert jq -e '.mcp."todoist".type == "local"' "$CONFIG_FILE"
    assert jq -e '.mcp."todoist".command == ["bunx", "-y", "mcp-remote", "https://ai.todoist.net/mcp"]' "$CONFIG_FILE"
    assert jq -e '.mcp."test-server".type == "remote"' "$CONFIG_FILE"
    assert jq -e '.mcp."test-server".url == "http://test.dev/mcp"' "$CONFIG_FILE"

    echo "Test Case 1: Initial creation and injection PASSED"

    # --- Test Case 2: Idempotency ---
    # Get a checksum of the current file
    checksum1=$(sha256sum "$CONFIG_FILE" | cut -d' ' -f1)

    # Re-run the activation script
    /nix/store/*-home-manager-*/bin/home-manager-generation

    # Get the new checksum
    checksum2=$(sha256sum "$CONFIG_FILE" | cut -d' ' -f1)

    # Assert that the file has not changed
    assert test "$checksum1" = "$checksum2"

    echo "Test Case 2: Idempotency PASSED"

    # --- Test Case 3: Plugin Update ---
    # Manually downgrade a plugin in the config file
    jq '(.plugin[] | select(. | startswith("my-test-plugin@"))) |= "my-test-plugin@v0.5.0"' "$CONFIG_FILE" > "$CONFIG_FILE.tmp"
    mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"

    # Re-run activation (which is configured with v1.0.0)
    /nix/store/*-home-manager-*/bin/home-manager-generation

    # Assert that the plugin was updated back to the version specified in the Nix config
    assert jq -e '.plugin | index("my-test-plugin@v1.0.0")' "$CONFIG_FILE"

    echo "Test Case 3: Plugin update PASSED"
  '';
}
