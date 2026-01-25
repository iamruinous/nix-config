# Kimaki Environment Secrets

**File:** `env.age`  
**Owner:** jmeskill (user secret)  
**Mode:** 400  
**Referenced by:** `hosts/chassis/users/jmeskill/home-configuration.nix`

## Purpose

Environment variables for Kimaki AI voice assistant Discord bot.

## Contents

| Variable | Description |
|----------|-------------|
| `ANTHROPIC_API_KEY` | API key for Anthropic Claude models |
| `OPENAI_API_KEY` | API key for OpenAI models (voice synthesis) |
| `GOOGLE_API_KEY` | API key for Google AI models |
| `XAI_API_KEY` | API key for xAI models (Grok) |
| `OPENROUTER_API_KEY` | API key for OpenRouter (multi-model gateway) |
| `EXA_API_KEY` | API key for Exa web search |
| `DISCORD_BOT_TOKEN` | Discord bot token for Kimaki voice bot |
| `DISCORD_APPLICATION_ID` | Discord application ID |

## Usage

This environment file is loaded by the Kimaki systemd user service:

```nix
ai-cli = {
  kimaki = {
    enable = true;
    environmentFiles = [
      config.age.secrets.chassis_kimaki_env.path
    ];
  };
};
```

## Related

- `hosts/chassis/users/jmeskill/home-configuration.nix` - Kimaki configuration
- `modules/home/default/ai-cli/kimaki.nix` - Kimaki module definition
