# Gemini Code Assistant Context

This file provides context to the Gemini code assistant to help it understand the structure and conventions of this NixOS configuration repository.

## Project Overview

This is a NixOS configuration repository that uses the `blueprint` flake to map the directory structure to flake outputs. It manages the configurations for multiple NixOS and Darwin (macOS) machines.

The repository is structured as follows:

-   `flake.nix`: The main entry point for the Nix flake, defining inputs and outputs.
-   `hosts/`: Contains the main configuration for each individual machine. Each machine has its own subdirectory (e.g., `hosts/framework/`) with a `configuration.nix`, `system-configuration.nix`, or `darwin-configuration.nix` file.
-   `modules/`: Contains reusable NixOS and home-manager modules that are imported by the host configurations.
    -   `modules/nixos/`: NixOS specific modules.
    -   `modules/darwin/`: Darwin specific modules.
    -   `modules/home/`: home-manager modules, with subdirectories for different operating systems.
-   `users/`: Contains user-specific configurations, primarily for home-manager.
-   `lib/`: Contains helper functions and libraries.
-   `packages/`: Contains custom packages.

## Building and Running

To build a specific host configuration, use the following command:

```bash
nixos-rebuild switch --flake .#<hostname>
```

For example, to build the configuration for the `framework` host, run:

```bash
nixos-rebuild switch --flake .#framework
```

To build a darwin configuration, use the following command:

```bash
darwin-rebuild switch --flake .#<hostname>
```

For example, to build the configuration for the `jbookpro` host, run:

```bash
darwin-rebuild switch --flake .#jbookpro
```

To build a system configuration, use the following command:

```bash
nix run 'github:numtide/system-manager' -- switch --flake .#<system>
```

For example, to build the configuration for the `pit` host, run:

```bash
nix run 'github:numtide/system-manager' -- switch --flake .#pit
```

## Development Conventions

-   **Modularity:** Configurations are highly modular, with reusable components in the `modules/` directory.
-   **Blueprint:** The `blueprint` flake is used to map the directory structure to flake outputs, which simplifies the `flake.nix` file.
-   **Secrets Management:** Secrets are managed using `agenix`.
-   **Home Manager:** User-specific configurations are managed with `home-manager`.
-   **Disko:** Some hosts use `disko` for declarative disk partitioning.
-   **Lanzaboote:** Some hosts use `lanzaboote` for secure boot.

## Git Workflow

This project adheres to the [Conventional Commits](https://www.conventionalcommits.org/) specification. This creates a structured and easily understandable commit history.

### Commit Message Format

Each commit message consists of a **header**, a **body**, and a **footer**.

```
<type>[optional scope]: <description>

[optional body]

[optional footer]
```

-   **type**: This describes the kind of change you're making. Common types include:
    -   `feat`: A new feature.
    -   `fix`: A bug fix.
    -   `docs`: Documentation only changes.
    -   `style`: Changes that do not affect the meaning of the code (white-space, formatting, missing semi-colons, etc).
    -   `refactor`: A code change that neither fixes a bug nor adds a feature.
    -   `test`: Adding missing tests or correcting existing tests.
    -   `chore`: Changes to the build process or auxiliary tools and libraries such as documentation generation.
-   **scope** (optional): This provides additional contextual information and is contained within parentheses, e.g., `feat(parser): add ability to parse arrays`.
-   **description**: A short, imperative-tense description of the change.

### Examples

```
feat: allow provided config object to extend other configs
```

```
fix(jbookpro): correct brew package installation
```

```
docs: explain the git workflow
```
