# forgejo-shell

A shell wrapper for SSH access to a Forgejo instance running in Docker.

## Description

This package provides a simple shell script that acts as a bridge between SSH connections and a Forgejo Docker container. When used as an SSH shell, it executes commands inside the `forgejo` Docker container as the `git` user.

## How it works

The shell wrapper:
- Receives the SSH command via the `SSH_ORIGINAL_COMMAND` environment variable
- Executes the command inside the `forgejo` Docker container using `docker exec`
- Runs commands as the `git` user within the container

## Usage

This is typically configured as the login shell for Git SSH access:

```nix
users.users.git = {
  shell = pkgs.forgejo-shell;
  # ...
};
```

When a user connects via SSH (e.g., `git clone ssh://git@host/repo.git`), the command is automatically forwarded to the Forgejo container.

## Dependencies

- Docker
- A running Forgejo container named `forgejo`
