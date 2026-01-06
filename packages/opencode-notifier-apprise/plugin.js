console.log("[apprise-notifier] File loaded");

const state = {
  initialized: false,
  lastSentMessage: null,
  lastSentTime: 0,
  lastMessageText: null,
  idleTimer: null
};

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

function extractQuestion(text) {
  if (!text || !text.includes('?')) return null;

  const paragraphs = text.split(/\n\s*\n/).map(p => p.trim()).filter(p => p);
  
  let questionBlock = [];
  let foundQuestion = false;
  
  for (let i = paragraphs.length - 1; i >= 0; i--) {
    const p = paragraphs[i];
    
    if (p.includes('?')) {
      foundQuestion = true;
      questionBlock.unshift(p);
    } else if (foundQuestion) {
      questionBlock.unshift(p);
      break;
    }
  }
  
  if (questionBlock.length > 0) {
    let result = questionBlock.join('\n\n');
    if (result.length > 400) {
      result = result.slice(0, 397) + "...";
    }
    return result;
  }

  return null;
}

async function sendNotification(config, message, title = "OpenCode", type = "info") {
  const now = Date.now();
  
  if (state.lastSentMessage === message && now - state.lastSentTime < 60000) return;
  if (now - state.lastSentTime < 10000) return;

  state.lastSentMessage = message;
  state.lastSentTime = now;

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
  if (state.initialized) return {};
  state.initialized = true;

  const config = getConfig();
  if (!config) return {};

  console.log("[apprise-notifier] Initialized");

  return {
    event: async ({ event }) => {
      if (event.type === "message.part.updated") {
        const part = event.properties?.part;
        if (part?.type === "text" && part?.text) {
          state.lastMessageText = part.text;
        }
      }

      if (event.type === "session.idle") {
        if (state.idleTimer) clearTimeout(state.idleTimer);
        
        state.idleTimer = setTimeout(async () => {
          state.idleTimer = null;
          const question = extractQuestion(state.lastMessageText);
          
          // Only notify if there's actually a question
          if (question) {
            await sendNotification(config, question, "OpenCode - Question", "info");
          }
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
