// OpenCode Harness Lifecycle Hooks Plugin
// Maps OpenCode events to harness lifecycle hooks.

import { appendFileSync, mkdirSync } from "fs";
import { join, dirname } from "path";

function getHarnessDataDir(directory) {
  return join(directory, ".harness", "data");
}

function appendToJsonl(dataDir, filename, entry) {
  const filepath = join(dataDir, filename);
  try {
    mkdirSync(dirname(filepath), { recursive: true });
    appendFileSync(filepath, JSON.stringify(entry) + "\n");
  } catch (err) {
    console.error(`Failed to append to ${filename}:`, err.message);
  }
}

function createEntry(event, data = {}) {
  return {
    timestamp: new Date().toISOString(),
    event,
    ...data,
  };
}

function generateId() {
  return Date.now().toString(36) + Math.random().toString(36).slice(2, 8);
}

export const HarnessHooks = async ({ directory }) => {
  const dataDir = getHarnessDataDir(directory);
  const callStartTimes = {};

  return {
    event: async ({ event }) => {
      const { type, properties } = event;

      // Session started → session-start hook
      if (type === "session.created") {
        appendToJsonl(dataDir, "events.jsonl", createEntry("HOOK_COMPLETED", {
          hook: "session-start",
          tool: "session.created",
          session_id: properties?.sessionID || properties?.info?.id || "unknown",
          success: true,
        }));
      }

      // Session idle → session-end hook
      if (type === "session.idle") {
        appendToJsonl(dataDir, "events.jsonl", createEntry("SESSION_IDLE", {
          session_id: properties?.sessionID || "unknown",
        }));
      }

      // Before tool execution → before-task / before-commit hooks
      if (type === "tool.execute.before") {
        const toolName = properties?.tool || "unknown";
        const callID = properties?.callID || generateId();
        const args = properties?.args || {};

        callStartTimes[callID] = Date.now();

        // Map tool to appropriate hook
        let hookName = "before-task";
        if (toolName === "write" || toolName === "edit") {
          hookName = "before-commit";
        }

        appendToJsonl(dataDir, "events.jsonl", createEntry("HOOK_COMPLETED", {
          hook: hookName,
          tool: toolName,
          callID,
          success: true,
        }));

        // Track skill usage
        if (toolName === "skill") {
          const skillName = args.name || args.skill || "unknown";
          appendToJsonl(dataDir, "events.jsonl", createEntry("SKILL_USED", {
            skill: skillName,
            callID,
          }));
        }

        // Track agent/subagent usage
        if (toolName === "task" || toolName === "subagent") {
          const agentName = args.description || args.agent || "unknown";
          appendToJsonl(dataDir, "agent_runs.jsonl", {
            timestamp: new Date().toISOString(),
            callID,
            agent: agentName,
            status: "running",
            started_at: new Date().toISOString(),
          });
        }
      }

      // After tool execution → after-task hook
      if (type === "tool.execute.after") {
        const toolName = properties?.tool || "unknown";
        const callID = properties?.callID || "unknown";
        const success = !properties?.error;

        const startTime = callStartTimes[callID] || Date.now();
        const durationMs = Date.now() - startTime;
        delete callStartTimes[callID];

        appendToJsonl(dataDir, "events.jsonl", createEntry("HOOK_COMPLETED", {
          hook: "after-task",
          tool: toolName,
          callID,
          success,
        }));

        // Complete agent run
        if (toolName === "task" || toolName === "subagent") {
          const agentName = properties?.args?.description || properties?.args?.agent || "unknown";
          appendToJsonl(dataDir, "agent_runs.jsonl", {
            timestamp: new Date().toISOString(),
            callID,
            agent: agentName,
            status: success ? "success" : "failed",
            started_at: new Date(startTime).toISOString(),
            completed_at: new Date().toISOString(),
            duration_ms: durationMs,
          });
        }
      }

      // File edits
      if (type === "file.edited") {
        appendToJsonl(dataDir, "events.jsonl", createEntry("FILE_EDITED", {
          file: properties?.filePath || "unknown",
        }));
      }

      // Permission requests
      if (type === "permission.asked") {
        appendToJsonl(dataDir, "events.jsonl", createEntry("PERMISSION_REQUESTED", {
          tool: properties?.tool || "unknown",
        }));
      }
    },
  };
};