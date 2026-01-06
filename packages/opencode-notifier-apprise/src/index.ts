/**
 * OpenCode Apprise Notification Plugin
 *
 * Sends notifications via Apprise API when OpenCode needs user attention:
 * - Session idle (waiting for user input)
 * - Permission requests
 * - Session errors
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

import type { Plugin } from "@opencode-ai/plugin";

interface NotifyConfig {
  appriseUrl: string;
  appriseConfigKey?: string;
  appriseUrls?: string;
  appriseTag?: string;
  idleDelay: number;
  notifyOnPermission: boolean;
  notifyOnError: boolean;
}

function getConfig(): NotifyConfig | null {
  const appriseUrl = process.env.OPENCODE_NOTIFIER_APPRISE_URL;
  if (!appriseUrl) {
    console.warn(
      "[opencode-notifier-apprise] OPENCODE_NOTIFIER_APPRISE_URL not set, notifications disabled"
    );
    return null;
  }

  return {
    appriseUrl,
    appriseConfigKey: process.env.OPENCODE_NOTIFIER_APPRISE_CONFIG_KEY,
    appriseUrls: process.env.OPENCODE_NOTIFIER_APPRISE_URLS,
    appriseTag: process.env.OPENCODE_NOTIFIER_APPRISE_TAG,
    idleDelay: parseInt(process.env.OPENCODE_NOTIFIER_IDLE_DELAY ?? "5000", 10),
    notifyOnPermission:
      process.env.OPENCODE_NOTIFIER_ON_PERMISSION !== "false",
    notifyOnError: process.env.OPENCODE_NOTIFIER_ON_ERROR !== "false",
  };
}

async function sendNotification(
  config: NotifyConfig,
  message: string,
  title: string = "OpenCode",
  type: "info" | "success" | "warning" | "failure" = "info"
): Promise<void> {
  const baseUrl = config.appriseUrl.replace(/\/$/, "");
  const endpoint = config.appriseConfigKey
    ? `${baseUrl}/notify/${config.appriseConfigKey}/`
    : `${baseUrl}/`;

  const payload: Record<string, string> = {
    body: message,
    title,
    type,
    format: "text",
  };

  if (config.appriseUrls) {
    payload.urls = config.appriseUrls;
  }

  if (config.appriseTag) {
    payload.tag = config.appriseTag;
  }

  try {
    const response = await fetch(endpoint, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(payload),
    });

    if (!response.ok) {
      console.error(
        `[opencode-notifier-apprise] Failed to send notification: HTTP ${response.status}`
      );
    }
  } catch (error) {
    console.error("[opencode-notifier-apprise] Failed to send notification:", error);
  }
}

function extractSummary(text: string | null | undefined): string {
  if (!text) return "Session is waiting for input";

  // Try to extract a summary line
  const summaryMatch = text.match(/[_*]?Summary:[_*]?\s*(.+?)(?:\n|$)/i);
  if (summaryMatch?.[1]) {
    return summaryMatch[1].trim();
  }

  // Try to find a question
  const questionMatch = text.match(/[^.!?]*\?[^.!?]*/);
  if (questionMatch) {
    const question = questionMatch[0].trim();
    if (question.length <= 200) {
      return question;
    }
  }

  // Truncate if too long
  if (text.length > 100) {
    return text.slice(0, 100).trim() + "...";
  }

  return text;
}

export const AppriseNotifierPlugin: Plugin = async ({
  client,
  project,
}) => {
  const config = getConfig();

  if (!config) {
    // Return empty hooks if not configured
    return {};
  }

  let lastMessageText: string | null = null;
  let idleTimer: ReturnType<typeof setTimeout> | null = null;

  console.log(
    `[opencode-notifier-apprise] Enabled - sending to ${config.appriseUrl}`
  );

  return {
    event: async ({ event }) => {
      // Track the last assistant message for context
      if (event.type === "message.part.updated") {
        const part = (event as any).properties?.part;
        if (part?.type === "text" && part?.text) {
          lastMessageText = part.text;
        }
      }

      // Handle session idle - waiting for user input
      if (event.type === "session.idle") {
        // Clear any existing timer
        if (idleTimer) {
          clearTimeout(idleTimer);
        }

        // Delay notification to avoid spamming during quick interactions
        idleTimer = setTimeout(async () => {
          const summary = extractSummary(lastMessageText);
          await sendNotification(
            config,
            summary,
            "OpenCode - Waiting for Input",
            "info"
          );
        }, config.idleDelay);
      }

      // Handle permission requests
      if (event.type === "permission.asked" && config.notifyOnPermission) {
        const props = (event as any).properties;
        const permission = props?.permission ?? "unknown action";
        const patterns = props?.patterns?.join(", ") ?? "";

        const message = patterns
          ? `Permission needed: ${permission}\nPatterns: ${patterns}`
          : `Permission needed: ${permission}`;

        await sendNotification(
          config,
          message,
          "OpenCode - Permission Required",
          "warning"
        );
      }

      // Handle session errors
      if (event.type === "session.error" && config.notifyOnError) {
        const props = (event as any).properties;
        const error = props?.error ?? "Unknown error occurred";

        await sendNotification(
          config,
          String(error),
          "OpenCode - Error",
          "failure"
        );
      }

      // Clear idle timer on new activity
      if (
        event.type === "message.updated" ||
        event.type === "message.part.updated"
      ) {
        if (idleTimer) {
          clearTimeout(idleTimer);
          idleTimer = null;
        }
      }
    },
  };
};

// Default export for OpenCode plugin loading
export default AppriseNotifierPlugin;
