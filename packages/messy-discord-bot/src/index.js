// messy-discord-bot - Discord bot that forwards messages to n8n webhook
const { Client, GatewayIntentBits } = require('discord.js');

const client = new Client({
  intents: [
    GatewayIntentBits.Guilds,
    GatewayIntentBits.GuildMessages,
    GatewayIntentBits.MessageContent
  ]
});

const N8N_WEBHOOK_URL = process.env.N8N_WEBHOOK_URL;
const MESSY_CHANNEL_ID = process.env.MESSY_CHANNEL_ID;

// Validate required environment variables
if (!process.env.DISCORD_BOT_TOKEN) {
  console.error('ERROR: DISCORD_BOT_TOKEN environment variable is required');
  process.exit(1);
}

if (!N8N_WEBHOOK_URL) {
  console.error('ERROR: N8N_WEBHOOK_URL environment variable is required');
  process.exit(1);
}

if (!MESSY_CHANNEL_ID) {
  console.error('ERROR: MESSY_CHANNEL_ID environment variable is required');
  process.exit(1);
}

client.on('ready', () => {
  console.log(`Logged in as ${client.user.tag}`);
  console.log(`Listening for messages in channel ID: ${MESSY_CHANNEL_ID}`);
  console.log(`Forwarding to webhook: ${N8N_WEBHOOK_URL}`);
});

client.on('messageCreate', async (message) => {
  // Filter: only the configured channel
  if (message.channel.id !== MESSY_CHANNEL_ID) return;

  // Filter: ignore bot messages (including self)
  if (message.author.bot) return;

  console.log(`Received message from ${message.author.username}: ${message.content.substring(0, 50)}...`);

  // Typing indicator interval to keep showing while processing
  let typingInterval = null;

  try {
    // Show typing indicator immediately
    await message.channel.sendTyping();

    // Refresh typing indicator every 9 seconds (Discord auto-stops after 10)
    typingInterval = setInterval(() => {
      message.channel.sendTyping().catch(() => {});
    }, 9000);

    // Forward to n8n webhook
    const response = await fetch(N8N_WEBHOOK_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        message: {
          content: message.content,
          id: message.id,
          timestamp: message.createdAt.toISOString()
        },
        author: {
          id: message.author.id,
          username: message.author.username,
          displayName: message.author.displayName
        },
        channel: {
          id: message.channel.id,
          name: message.channel.name
        },
        guild: {
          id: message.guild.id,
          name: message.guild.name
        }
      })
    });

    // Stop typing indicator
    if (typingInterval) {
      clearInterval(typingInterval);
      typingInterval = null;
    }

    // Get response from n8n and send to Discord
    if (response.ok) {
      const data = await response.json();
      if (data.response) {
        // Discord has a 2000 character limit per message
        const responseText = data.response;
        if (responseText.length <= 2000) {
          await message.channel.send(responseText);
        } else {
          // Split long messages
          const chunks = splitMessage(responseText, 2000);
          for (const chunk of chunks) {
            await message.channel.send(chunk);
          }
        }
      }
    } else {
      console.error(`Webhook returned status ${response.status}`);
      await message.channel.send('Sorry, I encountered an error processing your request.');
    }
  } catch (error) {
    console.error('Error processing message:', error);

    // Stop typing indicator on error
    if (typingInterval) {
      clearInterval(typingInterval);
    }

    await message.channel.send('Sorry, I encountered an error processing your request.');
  }
});

// Helper function to split long messages
function splitMessage(text, maxLength) {
  const chunks = [];
  let remaining = text;

  while (remaining.length > 0) {
    if (remaining.length <= maxLength) {
      chunks.push(remaining);
      break;
    }

    // Try to split at a newline
    let splitIndex = remaining.lastIndexOf('\n', maxLength);
    if (splitIndex === -1 || splitIndex < maxLength / 2) {
      // Try to split at a space
      splitIndex = remaining.lastIndexOf(' ', maxLength);
    }
    if (splitIndex === -1 || splitIndex < maxLength / 2) {
      // Force split at maxLength
      splitIndex = maxLength;
    }

    chunks.push(remaining.substring(0, splitIndex));
    remaining = remaining.substring(splitIndex).trimStart();
  }

  return chunks;
}

// Handle graceful shutdown
process.on('SIGTERM', () => {
  console.log('Received SIGTERM, shutting down gracefully...');
  client.destroy();
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('Received SIGINT, shutting down gracefully...');
  client.destroy();
  process.exit(0);
});

client.login(process.env.DISCORD_BOT_TOKEN);
