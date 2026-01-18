{pkgs, ...}:
pkgs.buildGoModule {
  pname = "budgey-extractor";
  version = "0.1.0";

  src = pkgs.fetchgit {
    url = "https://forge.meskill.farm/iamruinous/budgey-extractor.git";
    rev = "main";
    hash = pkgs.lib.fakeSha256;
  };

  vendorHash = pkgs.lib.fakeSha256;

  meta = with pkgs.lib; {
    description = "Offline OpenCode session extractor for Postgres + Weaviate";
    homepage = "https://forge.meskill.farm/iamruinous/budgey-extractor";
    license = licenses.mit;
    maintainers = [];
    platforms = platforms.linux;
  };
}
