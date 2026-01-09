{pkgs, ...}:
pkgs.stdenv.mkDerivation {
  pname = "opencode-anthropic-auth-patch";
  version = "0.0.6-oc";
  dontUnpack = true;

  propagatedBuildInputs = with pkgs; [
    nodejs
    coreutils
  ];

  buildPhase = ''
    mkdir -p $out/share/opencode-anthropic-auth-patch
    cp ${./index.mjs} $out/share/opencode-anthropic-auth-patch/index.mjs
    chmod +r $out/share/opencode-anthropic-auth-patch/index.mjs
  '';

  installPhase = ''
    # No additional installation steps needed
    true
  '';

  meta = with pkgs.lib; {
    description = "Patched OpenCode Anthropic auth plugin with tool renaming for OAuth compatibility";
    longDescription = ''
      A patched version of the opencode-anthropic-auth plugin that prefixes tool names
      with "oc_" in outgoing requests and strips the prefix in streaming responses.
      This allows OpenCode to use Claude OAuth credentials with MCP tools, working around
      the restriction that OAuth credentials are only authorized for Claude Code.

      Based on PR #10 from anomalyco/opencode-anthropic-auth by ashley-bytespell.
    '';
    homepage = "https://github.com/anomalyco/opencode-anthropic-auth/pull/10";
    license = licenses.mit;
    maintainers = [];
    platforms = platforms.unix;
  };
}
