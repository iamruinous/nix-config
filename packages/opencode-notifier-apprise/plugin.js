// Debug logging - enable with OPENCODE_NOTIFIER_DEBUG=1
const DEBUG = process.env.OPENCODE_NOTIFIER_DEBUG === "1";
const debug = (...args) => {
  if (DEBUG) {
    const mem = process.memoryUsage();
    const memMB = (mem.heapUsed / 1024 / 1024).toFixed(2);
    console.log(`[apprise-notifier:debug][${new Date().toISOString()}][heap:${memMB}MB]`, ...args);
  }
};

console.log("[apprise-notifier] File loaded");
debug("Debug mode enabled");

const state = {
  initialized: false,
  lastSentMessage: null,
  lastSentTime: 0,
  lastMessageText: null,
  idleTimer: null,
  eventCount: 0,
  timerSetCount: 0,
  timerClearedCount: 0,
  notificationsSent: 0
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
  
  debug(`sendNotification called: title="${title}", type="${type}", msgLen=${message?.length}`);
  
  if (state.lastSentMessage === message && now - state.lastSentTime < 60000) {
    debug("Skipped: duplicate message within 60s");
    return;
  }
  if (now - state.lastSentTime < 10000) {
    debug("Skipped: rate limited (within 10s of last send)");
    return;
  }

  state.lastSentMessage = message;
  state.lastSentTime = now;
  state.notificationsSent++;

  const baseUrl = config.appriseUrl.replace(/\/$/, "");
  const endpoint = config.appriseConfigKey 
    ? `${baseUrl}/notify/${config.appriseConfigKey}/` 
    : `${baseUrl}/`;

  const payload = { body: message, title, type, format: "text" };
  if (config.appriseTag) payload.tag = config.appriseTag;

  debug(`Sending notification #${state.notificationsSent} to ${endpoint}`);

  try {
    const startTime = Date.now();
    await fetch(endpoint, {
      method: "POST",
      headers: { "Content-Type: application/json" },
      body: JSON.stringify(payload)
    });
    debug(`Notification sent in ${Date.now() - startTime}ms`);
  } catch (error) {
    console.error("[apprise-notifier] Error:", error);
    debug(`Notification failed: ${error.message}`);
  }
}

export const AppriseNotifierPlugin = async () => {
  debug(`AppriseNotifierPlugin called, initialized=${state.initialized}`);
  
  if (state.initialized) {
    debug("Already initialized, returning empty object");
    return {};
  }
  state.initialized = true;

  const config = getConfig();
  if (!config) {
    debug("No config found (OPENCODE_NOTIFIER_APPRISE_URL not set)");
    return {};
  }

  console.log("[apprise-notifier] Initialized");
  debug(`Config: idleDelay=${config.idleDelay}ms, hasTag=${!!config.appriseTag}`);

  return {
    event: async ({ event }) => {
      state.eventCount++;
      debug(`Event #${state.eventCount}: ${event.type}`);
      
      if (event.type === "message.part.updated") {
        const part = event.properties?.part;
        if (part?.type === "text" && part?.text) {
          const oldLen = state.lastMessageText?.length ?? 0;
          state.lastMessageText = part.text;
          debug(`message.part.updated: stored text (${oldLen} -> ${part.text.length} chars)`);
        }
      }

      if (event.type === "session.idle") {
        if (state.idleTimer) {
          clearTimeout(state.idleTimer);
          state.timerClearedCount++;
          debug(`Cleared existing idle timer (cleared total: ${state.timerClearedCount})`);
        }
        
        state.timerSetCount++;
        debug(`Setting idle timer #${state.timerSetCount} for ${config.idleDelay}ms`);
        
        state.idleTimer = setTimeout(async () => {
          debug(`Idle timer #${state.timerSetCount} fired`);
          state.idleTimer = null;
          const question = extractQuestion(state.lastMessageText);
          
          if (question) {
            debug(`Found question (${question.length} chars), sending notification`);
            await sendNotification(config, question, "OpenCode - Question", "info");
          } else {
            debug("No question found, skipping notification");
          }
        }, config.idleDelay);
      }

      if (event.type === "permission.asked") {
        const permission = event.properties?.permission ?? "unknown";
        debug(`Permission asked: ${permission}`);
        await sendNotification(config, `Permission: ${permission}`, "OpenCode - Permission", "warning");
      }

      if (event.type === "session.error") {
        const error = event.properties?.error ?? "Unknown error";
        debug(`Session error: ${error}`);
        await sendNotification(config, String(error), "OpenCode - Error", "failure");
      }
      
      // Periodic stats in debug mode
      if (DEBUG && state.eventCount % 100 === 0) {
        debug(`Stats: events=${state.eventCount}, timersSet=${state.timerSetCount}, timersCleared=${state.timerClearedCount}, notifications=${state.notificationsSent}`);
      }
    }
  };
};

export default AppriseNotifierPlugin;
