{pkgs, ...}:
pkgs.buildGoModule {
  pname = "budgey-extractor";
  version = "0.6.0";

  src = pkgs.fetchgit {
    url = "https://forge.meskill.farm/iamruinous/budgey-extractor.git";
    rev = "v0.6.0";
    hash = "sha256-kr+g1TQM7EEFo3mjddwDpWG7zJUiES93xjmjkYumm5I=";
  };

  vendorHash = "sha256-Ua7FWJS4WRwRxy9qVNZW3Ie9Gp45HSItFmj/uGd6F8g=";

  postInstall = ''
    mkdir -p $out/share/budgey-extractor
    cp -r db/migrations $out/share/budgey-extractor/
  '';

  meta = with pkgs.lib; {
    description = "Offline OpenCode session extractor for Postgres + Weaviate";
    homepage = "https://forge.meskill.farm/iamruinous/budgey-extractor";
    license = licenses.mit;
    maintainers = [];
    platforms = platforms.linux ++ platforms.darwin;
  };
}
