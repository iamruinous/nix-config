#!/usr/bin/env bash

# Parse the command into an array
read -ra cmd_array <<< "$SSH_ORIGINAL_COMMAND"
base_cmd="${cmd_array[0]}"

case "$base_cmd" in
    ls)
        # Validate ls arguments (allow common flags)
        for arg in "${cmd_array[@]:1}"; do
            if [[ ! "$arg" =~ ^(-[alhdrtS]+|/.*)$ ]]; then
                echo "Error: Invalid argument for ls: $arg" >&2
                exit 1
            fi
        done
        exec $SSH_ORIGINAL_COMMAND
        ;;

    docker)
        # Only allow specific docker subcommands
        subcmd="${cmd_array[1]}"
        case "$subcmd" in
            ps|images|logs)
                exec $SSH_ORIGINAL_COMMAND
                ;;
            *)
                echo "Error: Docker subcommand '$subcmd' not allowed" >&2
                exit 1
                ;;
        esac
        ;;

    *)
        echo "Error: Command '$base_cmd' not allowed" >&2
        exit 1
        ;;
esac

