{ pkgs, ... }:

pkgs.python3Packages.buildPythonApplication rec {
  pname = "weaviate-cli";
  version = "3.2.4";
  format = "pyproject";

  src = pkgs.fetchFromGitHub {
    owner = "weaviate";
    repo = "weaviate-cli";
    rev = "v${version}";
    hash = "sha256-qHC+tMAwm9KLhR1vF6i4NJFm+PriBX3H0k2F3lYIteg=";
  };

  nativeBuildInputs = with pkgs.python3Packages; [
    setuptools
    setuptools-scm
    wheel
  ];

  propagatedBuildInputs = with pkgs.python3Packages; [
    weaviate-client
    click
    semver
    numpy
    importlib-resources
    prettytable
    faker
    matplotlib
  ];

  meta = with pkgs.lib; {
    description = "Command line interface to interact with weaviate";
    homepage = "https://github.com/weaviate/weaviate-cli";
    license = licenses.bsd3;
    maintainers = [];
    mainProgram = "weaviate-cli";
  };
}
