---
name: create-nix-package
description: Create a new Nix package from source code or binary
compatibility: Requires nix
metadata:
  author: ruinous.ai
  version: "1.0"
  domain: packaging
---

# Create Nix Package

Create a new Nix package from source code, a binary, or a script.

**Arguments:** `$ARGUMENTS` should contain:
- Package name (e.g., `myapp`)
- Source type (git, url, local)
- Language/build system (rust, python, go, shell, binary)

## Package Directory Structure

```
packages/<package-name>/
├── default.nix      # Package definition
└── README.md        # Documentation (optional but recommended)
```

## Steps

### 1. Create package directory
```bash
mkdir -p packages/<package-name>
```

### 2. Create default.nix

Choose the appropriate template based on source type.

### 3. Build and test
```bash
nix build .#<package-name>
./result/bin/<program> --version
```

### 4. Document in README.md

### 5. Update packages/README.md with entry

## Templates

### Shell Script Package
```nix
{ lib, stdenv, makeWrapper, bash, coreutils }:

stdenv.mkDerivation rec {
  pname = "script-name";
  version = "1.0.0";

  src = ./.;

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ bash ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp script.sh $out/bin/${pname}
    chmod +x $out/bin/${pname}
    wrapProgram $out/bin/${pname} \
      --prefix PATH : ${lib.makeBinPath [ coreutils ]}
    runHook postInstall
  '';

  meta = with lib; {
    description = "Description";
    homepage = "https://github.com/user/repo";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
```

### Rust Package
```nix
{ lib, rustPlatform, fetchFromGitHub, pkg-config, openssl }:

rustPlatform.buildRustPackage rec {
  pname = "package-name";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "user";
    repo = "repo";
    rev = "v${version}";
    hash = "sha256-AAAA...";
  };

  cargoHash = "sha256-BBBB...";

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl ];

  meta = with lib; {
    description = "Description";
    homepage = "https://github.com/user/repo";
    license = licenses.mit;
    mainProgram = "package-name";
  };
}
```

### Python Package
```nix
{ lib, python3Packages, fetchFromGitHub }:

python3Packages.buildPythonPackage rec {
  pname = "package-name";
  version = "1.0.0";
  format = "pyproject";

  src = fetchFromGitHub {
    owner = "user";
    repo = "repo";
    rev = "v${version}";
    hash = "sha256-AAAA...";
  };

  nativeBuildInputs = with python3Packages; [ setuptools wheel ];
  propagatedBuildInputs = with python3Packages; [ requests click ];

  pythonImportsCheck = [ "package_name" ];

  meta = with lib; {
    description = "Description";
    homepage = "https://github.com/user/repo";
    license = licenses.mit;
  };
}
```

### Go Module
```nix
{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "package-name";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "user";
    repo = "repo";
    rev = "v${version}";
    hash = "sha256-AAAA...";
  };

  vendorHash = "sha256-BBBB...";

  meta = with lib; {
    description = "Description";
    homepage = "https://github.com/user/repo";
    license = licenses.mit;
    mainProgram = "package-name";
  };
}
```

## Getting Hashes

```bash
# Get hash from build error (use lib.fakeHash first)
nix build .#package-name 2>&1 | grep "got:" | awk '{print $2}'

# Or use nix-prefetch
nix-prefetch-github user repo --rev v1.0.0
```

## Best Practices

- Always use fixed versions (never "latest")
- Use proper hash formats (sha256)
- Pin all dependencies explicitly
- Use `dontBuild = true` for scripts
- Add `mainProgram` for primary executable
- Document in README.md

## Example

```bash
/create-nix-package myapp git rust
```
