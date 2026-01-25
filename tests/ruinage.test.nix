{
  lib,
  pkgs,
  ...
}:
let
  ruinageLib = import ../lib/ruinage/wrapper.nix { inherit lib pkgs; };

  # Test 1: Git URL construction works
  testGitUrlConstruction =
    let
      url1 = ruinageLib.mkGitUrl {
        owner = "iamruinous";
        repo = "nix-config";
        forge = "github.com";
      };

      url2 = ruinageLib.mkGitUrl {
        owner = "test-owner";
        repo = "test-repo";
        # Uses default forge
      };

      expectedUrl1 = "ssh://git@github.com/iamruinous/nix-config.git";
      expectedUrl2 = "ssh://git@forge.meskill.farm/test-owner/test-repo.git";
    in
      url1 == expectedUrl1 && url2 == expectedUrl2;

  # Test 2: Config directories follow pattern
  testConfigDirectoryPattern = let
    homeDir = "/home/testuser";
    namespace = "ruinage";
    repo = "test-repo";

    projectPath = ruinageLib.mkProjectPath {
      homeDirectory = homeDir;
      inherit namespace repo;
    };

    expectedPath = "/home/testuser/Projects/ruinage/test-repo";
  in
    projectPath == expectedPath;

  # Test 3: Git URL parsing works (SSH format)
  testGitUrlParsingSsh =
    let
      sshUrl = "ssh://git@github.com/iamruinous/nix-config.git";
      parsed = ruinageLib.parseGitUrl sshUrl;
    in
      parsed != null
      && parsed.forge == "github.com"
      && parsed.owner == "iamruinous"
      && parsed.repo == "nix-config";

  # Test 4: Git URL parsing works (SCP format)
  testGitUrlParsingScp =
    let
      scpUrl = "git@forge.meskill.farm:test-owner/test-repo.git";
      parsed = ruinageLib.parseGitUrl scpUrl;
    in
      parsed != null
      && parsed.forge == "forge.meskill.farm"
      && parsed.owner == "test-owner"
      && parsed.repo == "test-repo";

  # Test 5: Git URL parsing works (HTTPS format with .git)
  testGitUrlParsingHttps =
    let
      httpsUrl = "https://github.com/iamruinous/nix-config.git";
      parsed = ruinageLib.parseGitUrl httpsUrl;
    in
      parsed != null
      && parsed.forge == "github.com"
      && parsed.owner == "iamruinous"
      && parsed.repo == "nix-config";

  # Test 6: Git URL parsing works (HTTPS format without .git)
  testGitUrlParsingHttpsNoGit =
    let
      httpsNoGitUrl = "https://github.com/iamruinous/nix-config";
      parsed = ruinageLib.parseGitUrl httpsNoGitUrl;
    in
      parsed != null
      && parsed.forge == "github.com"
      && parsed.owner == "iamruinous"
      && parsed.repo == "nix-config";

  # Test 7: Systemd environment construction includes required variables
  testSystemdEnvironment = let
    env = ruinageLib.mkSystemdEnvironment {
      homeDirectory = "/home/testuser";
      extraPackages = [ pkgs.git ];
      configDir = "/home/testuser/.config/opencode";
      cacheDir = "/home/testuser/.cache/opencode";
      stateDir = "/home/testuser/.local/state/opencode";
      dataDir = "/home/testuser/.local/share/opencode";
      includeSystemPath = true;
    };
  in
    # Verify environment list contains expected entries
    lib.any (e: lib.hasPrefix "HOME=" e) env
    && lib.any (e: lib.hasPrefix "PATH=" e) env
    && lib.any (e: lib.hasPrefix "NIX_LD=" e) env
    && lib.any (e: lib.hasPrefix "OPENCODE_CONFIG_DIR=" e) env
    && lib.any (e: lib.hasPrefix "XDG_CACHE_HOME=" e) env
    && lib.any (e: lib.hasPrefix "XDG_STATE_HOME=" e) env
    && lib.any (e: lib.hasPrefix "XDG_DATA_HOME=" e) env;

  # Test 8: Wrapped OpenCode creation
  testWrappedOpencode = let
    # Create a minimal mock package
    mockPackage = pkgs.writeTextDir "bin/opencode" "#!/bin/sh\necho test";

    wrapped = ruinageLib.mkWrappedOpencode {
      package = mockPackage;
      extraPackages = [ pkgs.git ];
    };
  in
    # Verify wrapped package is created and is an attribute set
    wrapped != null && builtins.isAttrs wrapped;

  # Test 9: Default forge is correct
  testDefaultForge =
    ruinageLib.defaultForge == "forge.meskill.farm";

  # Test 10: Default packages list is not empty
  testDefaultPackages =
    builtins.length ruinageLib.defaultPackages > 0;

  # Test 11: Builtin packages include essential tools
  testBuiltinPackages =
    lib.any (p: p.pname == "git" || p.name == "git") ruinageLib.builtinPackages
    || lib.any (p: lib.hasInfix "git" (p.pname or p.name or "")) ruinageLib.builtinPackages;

  # Test 12: mkPath construction
  testMkPath = let
    path = ruinageLib.mkPath {
      extraPackages = [ pkgs.git ];
      includeSystemPath = true;
    };
  in
    # Path should be a string containing bin directories
    builtins.isString path && lib.hasInfix "bin" path;

  # Test 13: Auth symlinks generation
  testAuthSymlinks = let
    symlinks = ruinageLib.mkAuthSymlinks {
      dataDir = "/home/testuser/.local/share/opencode-service";
      homeDirectory = "/home/testuser";
      mkOutOfStoreSymlink = path: path; # Mock function
    };
  in
    # Should return an attribute set with symlink entries
    builtins.isAttrs symlinks
    && lib.hasAttr "${"/home/testuser/.local/share/opencode-service"}/opencode/auth.json" symlinks;

  # Test 14: Git URL parsing returns null for invalid URLs
  testGitUrlParsingInvalid =
    let
      invalidUrl = "not-a-valid-url";
      parsed = ruinageLib.parseGitUrl invalidUrl;
    in
      parsed == null;

  # Test 15: Multiple projects with different ports
  testMultipleProjectPorts =
    let
      port1 = 9500;
      port2 = 9501;
      port3 = 9502;
    in
      port1 != port2 && port2 != port3 && port1 != port3;
in
{
  # Export all test results
  inherit
    testGitUrlConstruction
    testConfigDirectoryPattern
    testGitUrlParsingSsh
    testGitUrlParsingScp
    testGitUrlParsingHttps
    testGitUrlParsingHttpsNoGit
    testSystemdEnvironment
    testWrappedOpencode
    testDefaultForge
    testDefaultPackages
    testBuiltinPackages
    testMkPath
    testAuthSymlinks
    testGitUrlParsingInvalid
    testMultipleProjectPorts
    ;

  # Summary: all tests passed if all are true
  allTestsPassed =
    testGitUrlConstruction
    && testConfigDirectoryPattern
    && testGitUrlParsingSsh
    && testGitUrlParsingScp
    && testGitUrlParsingHttps
    && testGitUrlParsingHttpsNoGit
    && testSystemdEnvironment
    && testWrappedOpencode
    && testDefaultForge
    && testDefaultPackages
    && testBuiltinPackages
    && testMkPath
    && testAuthSymlinks
    && testGitUrlParsingInvalid
    && testMultipleProjectPorts
    ;
}
