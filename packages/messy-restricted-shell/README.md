# messy-restricted-shell

A restricted shell for SSH access that allows only specific whitelisted commands.

## Description

This package provides a restricted shell that validates and restricts SSH commands to a predefined safe set. It's designed to provide limited read-only access to system information while preventing unauthorized command execution.

## Allowed Commands

The shell permits the following commands:

### `ls`
- Allowed with common flags: `-a`, `-l`, `-h`, `-d`, `-r`, `-t`, `-S` (and combinations)
- Can be used with absolute paths (starting with `/`)
- Example: `ls -la /var/log`

### `docker`
- Only the following subcommands are allowed:
  - `docker ps` - List containers
  - `docker images` - List images
  - `docker logs` - View container logs

Any other commands or arguments will be rejected with an error message.

## Usage

Configure this as the login shell for restricted SSH users:

```nix
users.users.restricted-user = {
  shell = pkgs.messy-restricted-shell;
  # ...
};
```

## Security

The shell validates commands before execution:
- Only whitelisted base commands are allowed
- Arguments are validated against patterns to prevent command injection
- Invalid commands result in error messages and exit code 1
- All validation errors are sent to stderr

## Dependencies

- bash
- docker (for docker commands)
