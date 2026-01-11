{pkgs, ...}: let
  pinentry-1password = pkgs.stdenv.mkDerivation {
    pname = "pinentry-1password";
    version = "0.1.0";
    dontUnpack = true;

    propagatedBuildInputs = [
      pkgs.coreutils
    ];

    passthru.shellPath = "/bin/pinentry-1password";
    outputs = ["out"];

    buildPhase = ''
      mkdir -p $out/bin
      cp ${./pinentry-1password.sh} $out/bin/pinentry-1password
      chmod +x $out/bin/pinentry-1password
    '';

    installPhase = ''
      # No installation steps needed beyond what's done in buildPhase
      true
    '';

    meta = with pkgs.lib; {
      description = "1Password CLI pinentry program for GPG-Agent and rage";
      homepage = "https://github.com/iamruinous/nix-config";
      license = licenses.mit;
      maintainers = [];
      mainProgram = "pinentry-1password";
      platforms = platforms.unix;
    };
  };

  # Mock op command for testing
  mockOp = pkgs.writeShellScriptBin "op" ''
    # Mock 1Password CLI for testing
    if [[ "$1" == "read" ]]; then
      case "$2" in
        "op://test/secret/password")
          echo "test-password-123"
          exit 0
          ;;
        "op://test/fail/password")
          echo "error: item not found" >&2
          exit 1
          ;;
        *)
          echo "error: unknown item" >&2
          exit 1
          ;;
      esac
    fi
    echo "error: unknown command" >&2
    exit 1
  '';
in
  pinentry-1password
  // {
    passthru.tests = {
      # Test 1: Initial greeting
      greeting = pkgs.runCommand "test-pinentry-1password-greeting" {} ''
        result=$(echo "BYE" | ${pinentry-1password}/bin/pinentry-1password)
        if echo "$result" | grep -q "OK Pleased to meet you"; then
          echo "PASS: Greeting received" > $out
        else
          echo "FAIL: Expected greeting"
          echo "Got: $result"
          exit 1
        fi
      '';

      # Test 2: GETINFO version
      getinfo-version = pkgs.runCommand "test-pinentry-1password-getinfo-version" {} ''
        result=$(echo -e "GETINFO version\nBYE" | ${pinentry-1password}/bin/pinentry-1password)
        if echo "$result" | grep -q "D 0.1.0"; then
          echo "PASS: Version info correct" > $out
        else
          echo "FAIL: Expected version 0.1.0"
          echo "Got: $result"
          exit 1
        fi
      '';

      # Test 3: GETINFO pid
      getinfo-pid = pkgs.runCommand "test-pinentry-1password-getinfo-pid" {} ''
        result=$(echo -e "GETINFO pid\nBYE" | ${pinentry-1password}/bin/pinentry-1password)
        if echo "$result" | grep -q "D [0-9]"; then
          echo "PASS: PID returned" > $out
        else
          echo "FAIL: Expected PID"
          echo "Got: $result"
          exit 1
        fi
      '';

      # Test 4: GETINFO flavor
      getinfo-flavor = pkgs.runCommand "test-pinentry-1password-getinfo-flavor" {} ''
        result=$(echo -e "GETINFO flavor\nBYE" | ${pinentry-1password}/bin/pinentry-1password)
        if echo "$result" | grep -q "D 1password"; then
          echo "PASS: Flavor is 1password" > $out
        else
          echo "FAIL: Expected flavor 1password"
          echo "Got: $result"
          exit 1
        fi
      '';

      # Test 5: GETPIN with OP_PIN_ITEM (using mock op)
      getpin-op-pin-item = pkgs.runCommand "test-pinentry-1password-getpin-op-pin-item" {} ''
        export PATH="${mockOp}/bin:$PATH"
        export OP_PIN_ITEM="op://test/secret/password"
        result=$(echo -e "GETPIN\nBYE" | ${pinentry-1password}/bin/pinentry-1password)
        if echo "$result" | grep -q "D test-password-123"; then
          echo "PASS: GETPIN returned password via OP_PIN_ITEM" > $out
        else
          echo "FAIL: Expected password via OP_PIN_ITEM"
          echo "Got: $result"
          exit 1
        fi
      '';

      # Test 6: GETPIN with PINENTRY_USER_DATA (takes precedence over OP_PIN_ITEM)
      getpin-pinentry-user-data = pkgs.runCommand "test-pinentry-1password-getpin-pinentry-user-data" {} ''
        export PATH="${mockOp}/bin:$PATH"
        export OP_PIN_ITEM="op://test/fail/password"  # This would fail
        export PINENTRY_USER_DATA="op://test/secret/password"  # This should be used instead
        result=$(echo -e "GETPIN\nBYE" | ${pinentry-1password}/bin/pinentry-1password)
        if echo "$result" | grep -q "D test-password-123"; then
          echo "PASS: GETPIN used PINENTRY_USER_DATA over OP_PIN_ITEM" > $out
        else
          echo "FAIL: Expected PINENTRY_USER_DATA to take precedence"
          echo "Got: $result"
          exit 1
        fi
      '';

      # Test 7: GETPIN without config returns error
      getpin-no-config = pkgs.runCommand "test-pinentry-1password-getpin-no-config" {} ''
        unset OP_PIN_ITEM
        unset PINENTRY_USER_DATA
        result=$(echo -e "GETPIN\nBYE" | ${pinentry-1password}/bin/pinentry-1password)
        if echo "$result" | grep -q "ERR.*No OP_PIN_ITEM"; then
          echo "PASS: Error returned when no config" > $out
        else
          echo "FAIL: Expected error about missing config"
          echo "Got: $result"
          exit 1
        fi
      '';

      # Test 8: SET* commands return OK
      set-commands = pkgs.runCommand "test-pinentry-1password-set-commands" {} ''
        result=$(echo -e "SETDESC Test description\nSETPROMPT Passphrase:\nSETTITLE Title\nSETOK OK\nSETCANCEL Cancel\nBYE" | ${pinentry-1password}/bin/pinentry-1password)
        # Count OK responses (should be 6: greeting + 5 SET commands + BYE)
        ok_count=$(echo "$result" | grep -c "^OK" || true)
        if [[ "$ok_count" -ge 6 ]]; then
          echo "PASS: SET commands return OK" > $out
        else
          echo "FAIL: Expected at least 6 OK responses"
          echo "Got: $result"
          echo "OK count: $ok_count"
          exit 1
        fi
      '';

      # Test 9: OPTION command returns OK
      option-command = pkgs.runCommand "test-pinentry-1password-option" {} ''
        result=$(echo -e "OPTION grab\nOPTION ttyname=/dev/tty\nBYE" | ${pinentry-1password}/bin/pinentry-1password)
        if echo "$result" | grep -q "^OK"; then
          echo "PASS: OPTION commands return OK" > $out
        else
          echo "FAIL: Expected OK for OPTION commands"
          echo "Got: $result"
          exit 1
        fi
      '';

      # Test 10: RESET clears state
      reset-command = pkgs.runCommand "test-pinentry-1password-reset" {} ''
        result=$(echo -e "SETDESC Test\nRESET\nBYE" | ${pinentry-1password}/bin/pinentry-1password)
        if echo "$result" | grep -q "^OK"; then
          echo "PASS: RESET command works" > $out
        else
          echo "FAIL: Expected OK for RESET"
          echo "Got: $result"
          exit 1
        fi
      '';

      # Test 11: GETPIN failure returns error
      getpin-failure = pkgs.runCommand "test-pinentry-1password-getpin-failure" {} ''
        export PATH="${mockOp}/bin:$PATH"
        export OP_PIN_ITEM="op://test/fail/password"
        result=$(echo -e "GETPIN\nBYE" | ${pinentry-1password}/bin/pinentry-1password)
        if echo "$result" | grep -q "ERR.*Failed to read"; then
          echo "PASS: GETPIN failure returns error" > $out
        else
          echo "FAIL: Expected error on GETPIN failure"
          echo "Got: $result"
          exit 1
        fi
      '';

      # Test 12: CONFIRM returns OK (auto-confirms)
      confirm-command = pkgs.runCommand "test-pinentry-1password-confirm" {} ''
        result=$(echo -e "CONFIRM\nBYE" | ${pinentry-1password}/bin/pinentry-1password)
        if echo "$result" | grep -q "^OK"; then
          echo "PASS: CONFIRM auto-confirms" > $out
        else
          echo "FAIL: Expected OK for CONFIRM"
          echo "Got: $result"
          exit 1
        fi
      '';
    };
  }
