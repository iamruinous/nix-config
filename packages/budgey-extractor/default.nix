{pkgs, ...}:
pkgs.buildGoModule {
  pname = "budgey-extractor";
  version = "0.1.0";

  src = pkgs.fetchgit {
    url = "https://forge.meskill.farm/iamruinous/budgey-extractor.git";
    rev = "v0.1.0";
    hash = "sha256-RZvUXAQhuaRe2OEC3Dptu0Uyq8eBTx7Y7WDYQmzp6aw=";
  };

  vendorHash = "sha256-Ua7FWJS4WRwRxy9qVNZW3Ie9Gp45HSItFmj/uGd6F8g=";

  meta = with pkgs.lib; {
    description = "Offline OpenCode session extractor for Postgres + Weaviate";
    homepage = "https://forge.meskill.farm/iamruinous/budgey-extractor";
    license = licenses.mit;
    maintainers = [];
    platforms = platforms.linux;
  };
}
