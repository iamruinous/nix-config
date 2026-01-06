console.log("[apprise-notifier] Loaded");

function getConfig() {
  const appriseUrl = process.env.OPENCODE_NOTIFIER_APPRISE_URL;
  if (!appriseUrl) return null;
  return {
    appriseUrl,
    appriseConfigKey: process.env.OPENCODE_NOTIFIER_APPRISE_CONFIG_KEY,
    appriseTag: process.env.OPENCODE_NOTIFIER_APPRISE_TAG,
    idleDelay: parseInt(process.env.OPENCODE_NOTIFIER_IDLE_DELAY ?? "30000", 10),
  };
}

function extractSummary(text) {
  if (!text) return "Session waiting for input";

  const questionMatch = text.match(/[^.!?\n]*\?/g);
  if (questionMatch) {
    const question = questionMatch[questionMatch.length - 1].trim();
    if (question.length > 10 && question.length <= 200) {
      return question;
    }
  }

  const lines = text.trim().split('\n').filter(l => l.trim().length > 0);
  if (lines.length > 0) {
    const lastLine = lines[lines.length - 1].trim();
    if (lastLine.length <= 200) return lastLine;
    return lastLine.slice(0, 197) + "...";
  }

  return "Session waiting for input";
}

async function sendNotification(config, message, title = "OpenCode", type = "info") {
  const baseUrl = config.appriseUrl.replace(/\/$/, "");
  const endpoint = config.appriseConfigKey 
    ? `${baseUrl}/notify/${config.appriseConfigKey}/` 
    : `${baseUrl}/`;

  const payload = { body: message, title, type, format: "text" };
  if (config.appriseTag) payload.tag = config.appriseTag;

  try {
    await fetch(endpoint, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload)
    });
  } catch (error) {
    console.error("[apprise-notifier] Error:", error);
  }
}

export const AppriseNotifierPlugin = async () => {
  const config = getConfig();
  if (!config) return {};

  let lastMessageText = null;
  let idleTimer = null;
  let notificationSent = false;

  console.log("[apprise-notifier] Enabled, delay:", config.idleDelay);

  return {
    event: async ({ event }) => {
      // Track assistant messages
      if (event.type === "message.part.updated") {
        const part = event.properties?.part;
        if (part?.type === "text" && part?.text) {
          lastMessageText = part.text;
        }
      }

      // Reset state when new message activity
      if (event.type === "message.updated") {
        if (idleTimer) {
          clearTimeout(idleTimer);
          idleTimer = null;
        }
        notificationSent = false;
      }

      // Start idle timer
      if (event.type === "session.idle" && !notificationSent && !idleTimer) {
        idleTimer = setTimeout(async () => {
          idleTimer = null;
          notificationSent = true;
          const summary = extractSummary(lastMessageText);
          await sendNotification(config, summary, "OpenCode - Waiting", "info");
        }, config.idleDelay);
      }

      if (event.type === "permission.asked") {
        const permission = event.properties?.permission ?? "unknown";
        await sendNotification(config, `Permission: ${permission}`, "OpenCode - Permission", "warning");
      }

      if (event.type === "session.error") {
        const error = event.properties?.error ?? "Unknown error";
        await sendNotification(config, String(error), "OpenCode - Error", "failure");
      }
    }
  };
};

export default AppriseNotifierPlugin;
