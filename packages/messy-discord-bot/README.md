# messy-discord-bot

Discord bot that forwards messages from a specific channel to an n8n webhook for the Messy assistant.

## Purpose

This bot provides a bridge between Discord and n8n, enabling the Messy personal assistant to receive messages from Discord. It:

- Connects to Discord via the Gateway WebSocket
- Listens for messages in a configured channel (`MESSY_CHANNEL_ID`)
- Shows a typing indicator immediately when a message is received
- Forwards message content and metadata to an n8n webhook
- Sends the n8n response back to Discord

## Architecture

```
Discord #messy-chat -> Discord Bot -> n8n Webhook -> AI Agent -> Response -> Discord
```

## Development Setup

This package uses the `nodejs` devshell. To set up for development:

```bash
# Enter the package directory
cd packages/messy-discord-bot

# Allow direnv (loads nodejs devshell)
direnv allow

# Install dependencies
npm install

# Run locally (requires environment variables)
DISCORD_BOT_TOKEN=your_token \
N8N_WEBHOOK_URL=https://n8n.meskill.farm/webhook/discord-assistant \
MESSY_CHANNEL_ID=your_channel_id \
npm start
```

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `DISCORD_BOT_TOKEN` | Yes | Bot token from Discord Developer Portal |
| `N8N_WEBHOOK_URL` | Yes | n8n webhook URL for the Discord assistant workflow |
| `MESSY_CHANNEL_ID` | Yes | Discord channel ID to listen for messages |

## Discord Bot Setup

1. Go to [Discord Developer Portal](https://discord.com/developers/applications)
2. Create a new Application (e.g., "Messy Assistant")
3. Go to "Bot" section and create a bot
4. Enable these Privileged Gateway Intents:
   - MESSAGE CONTENT INTENT
   - SERVER MEMBERS INTENT (optional)
5. Copy the Bot Token
6. Go to OAuth2 > URL Generator:
   - Select scopes: `bot`
   - Select permissions: `Send Messages`, `Read Message History`, `View Channels`, `Embed Links`
   - Copy the URL and invite the bot to your server

## Building Docker Image

The Nix derivation builds a Docker image that can be loaded or pushed:

```bash
# Build the Docker image
nix build .#messy-discord-bot.dockerImage

# Load into Docker
docker load < result

# Or push to registry
skopeo copy docker-archive:result docker://ghcr.io/iamruinous/messy-discord-bot:1.0.0
```

## Deployment

The bot runs as a Docker container on monolith. See `hosts/monolith/containers.nix` for the container configuration.

## Message Payload

The bot sends this JSON payload to the n8n webhook:

```json
{
  "message": {
    "content": "User's message text",
    "id": "message_id",
    "timestamp": "2025-01-15T14:30:00.000Z"
  },
  "author": {
    "id": "user_id",
    "username": "username",
    "displayName": "Display Name"
  },
  "channel": {
    "id": "channel_id",
    "name": "messy-chat"
  },
  "guild": {
    "id": "guild_id",
    "name": "server_name"
  }
}
```

## Expected n8n Response

The n8n workflow should return:

```json
{
  "response": "The bot's response message"
}
```

## Version

1.0.0
