/**
 * OpenCode Apprise Notification Plugin
 * 
 * Sends notifications via Apprise API when OpenCode needs user attention.
 * 
 * Environment Variables:
 *   OPENCODE_NOTIFIER_APPRISE_URL        - Full endpoint URL, or base URL with CONFIG_KEY
 *   OPENCODE_NOTIFIER_APPRISE_CONFIG_KEY - Config key - builds {URL}/notify/{KEY}/
 *   OPENCODE_NOTIFIER_APPRISE_URLS       - Notification service URLs (optional)
 *   OPENCODE_NOTIFIER_APPRISE_TAG        - Filter by tag (optional)
 *   OPENCODE_NOTIFIER_IDLE_DELAY         - Delay in ms before idle notification (default: 5000)
 *   OPENCODE_NOTIFIER_ON_PERMISSION      - Notify on permission requests (default: true)
 *   OPENCODE_NOTIFIER_ON_ERROR           - Notify on session errors (default: true)
 */

function getConfig() {
  const appriseUrl = process.env.OPENCODE_NOTIFIER_APPRISE_URL;
  if (!appriseUrl) {
    console.warn("[opencode-notifier-apprise] OPENCODE_NOTIFIER_APPRISE_URL not set, notifications disabled");
    return null;
  }

  return {
    appriseUrl,
    appriseConfigKey: process.env.OPENCODE_NOTIFIER_APPRISE_CONFIG_KEY,
    appriseUrls: process.env.OPENCODE_NOTIFIER_APPRISE_URLS,
    appriseTag: process.env.OPENCODE_NOTIFIER_APPRISE_TAG,
    idleDelay: parseInt(process.env.OPENCODE_NOTIFIER_IDLE_DELAY ?? "5000", 10),
    notifyOnPermission: process.env.OPENCODE_NOTIFIER_ON_PERMISSION !== "false",
    notifyOnError: process.env.OPENCODE_NOTIFIER_ON_ERROR !== "false"
  };
}

async function sendNotification(config, message, title = "OpenCode", type = "info") {
  const baseUrl = config.appriseUrl.replace(/\/$/, "");
  const endpoint = config.appriseConfigKey 
    ? `${baseUrl}/notify/${config.appriseConfigKey}/` 
    : `${baseUrl}/`;

  const payload = { body: message, title, type, format: "text" };
  if (config.appriseUrls) payload.urls = config.appriseUrls;
  if (config.appriseTag) payload.tag = config.appriseTag;

  try {
    const response = await fetch(endpoint, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload)
    });
    if (!response.ok) {
      console.error(`[opencode-notifier-apprise] Failed to send notification: HTTP ${response.status}`);
    }
  } catch (error) {
    console.error("[opencode-notifier-apprise] Failed to send notification:", error);
  }
}

function extractSummary(text) {
  if (!text) return "Session is waiting for input";

  const summaryMatch = text.match(/[_*]?Summary:[_*]?\s*(.+?)(?:\n|$)/i);
  if (summaryMatch?.[1]) return summaryMatch[1].trim();

  const questionMatch = text.match(/[^.!?]*\?[^.!?]*/);
  if (questionMatch) {
    const question = questionMatch[0].trim();
    if (question.length <= 200) return question;
  }

  if (text.length > 100) return text.slice(0, 100).trim() + "...";
  return text;
}

export const AppriseNotifierPlugin = async ({ project }) => {
  const config = getConfig();
  if (!config) return {};

  let lastMessageText = null;
  let idleTimer = null;

  console.log(`[opencode-notifier-apprise] Enabled - sending to ${config.appriseUrl}`);

  return {
    event: async ({ event }) => {
      if (event.type === "message.part.updated") {
        const part = event.properties?.part;
        if (part?.type === "text" && part?.text) {
          lastMessageText = part.text;
        }
      }

      if (event.type === "session.idle") {
        if (idleTimer) clearTimeout(idleTimer);
        
        idleTimer = setTimeout(async () => {
          const summary = extractSummary(lastMessageText);
          await sendNotification(config, summary, "OpenCode - Waiting for Input", "info");
        }, config.idleDelay);
      }

      if (event.type === "permission.asked" && config.notifyOnPermission) {
        const props = event.properties;
        const permission = props?.permission ?? "unknown action";
        const patterns = props?.patterns?.join(", ") ?? "";
        const message = patterns
          ? `Permission needed: ${permission}\nPatterns: ${patterns}`
          : `Permission needed: ${permission}`;
        await sendNotification(config, message, "OpenCode - Permission Required", "warning");
      }

      if (event.type === "session.error" && config.notifyOnError) {
        const props = event.properties;
        const error = props?.error ?? "Unknown error occurred";
        await sendNotification(config, String(error), "OpenCode - Error", "failure");
      }

      if (event.type === "message.updated" || event.type === "message.part.updated") {
        if (idleTimer) {
          clearTimeout(idleTimer);
          idleTimer = null;
        }
      }
    }
  };
};

export default AppriseNotifierPlugin;
