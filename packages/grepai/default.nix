{pkgs, ...}:
pkgs.buildGoModule rec {
  pname = "grepai";
  version = "0.27.0";

  src = pkgs.fetchFromGitHub {
    owner = "yoanbernabeu";
    repo = "grepai";
    rev = "v${version}";
    hash = "sha256-Z5b+vKQGAitaGRE81oQyzoO5vcyUZIk8HujjUP5uGcM=";
  };

  vendorHash = "sha256-uHsx6l7k7ur295+DFGNUAvRG3j8K6uOKipyVCNtd0hs=";

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${version}"
  ];

  meta = with pkgs.lib; {
    description = "AI-powered semantic code search tool";
    homepage = "https://github.com/yoanbernabeu/grepai";
    license = licenses.mit;
    mainProgram = "grepai";
    platforms = platforms.unix;
  };
}
