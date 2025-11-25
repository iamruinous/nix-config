#!/bin/sh
@docker@/bin/docker exec -i --env SSH_ORIGINAL_COMMAND="$SSH_ORIGINAL_COMMAND" forgejo su git -c "$@"
