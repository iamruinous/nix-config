{pkgs, ...}:
pkgs.buildGoModule {
  pname = "budgey-extractor";
  version = "0.3.0";

  src = pkgs.fetchgit {
    url = "https://forge.meskill.farm/iamruinous/budgey-extractor.git";
    rev = "v0.3.0";
    hash = "sha256-lVBJRd0YiE3lNuCX9zpQbDu/ZV2KLUSbAt9jDpk2tTc=";
  };

  vendorHash = "sha256-Ua7FWJS4WRwRxy9qVNZW3Ie9Gp45HSItFmj/uGd6F8g=";

  meta = with pkgs.lib; {
    description = "Offline OpenCode session extractor for Postgres + Weaviate";
    homepage = "https://forge.meskill.farm/iamruinous/budgey-extractor";
    license = licenses.mit;
    maintainers = [];
    platforms = platforms.linux ++ platforms.darwin;
  };
}
