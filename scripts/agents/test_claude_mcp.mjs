#!/usr/bin/env node
/**
 * Minimal MCP stdio smoke against corebrum-mcp (Claude uses the same server).
 *
 * Prerequisites:
 *   cd /path/to/corebrum/contrib/corebrum-mcp && npm install && npm run build
 *
 * Usage:
 *   COREBRUM_URL=http://127.0.0.1:6502 \
 *   COREBRUM_MCP_JS=/path/to/corebrum/contrib/corebrum-mcp/dist/index.js \
 *   node test_claude_mcp.mjs
 *
 * Default COREBRUM_MCP_JS: ../../../corebrum/contrib/corebrum-mcp/dist/index.js
 *   relative to this file (sibling repo layout: Projects/corebrum + Projects/corebrum-examples)
 */
import { spawn } from "node:child_process";
import { createInterface } from "node:readline";
import { existsSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const defaultMcp = join(__dirname, "../../../corebrum/contrib/corebrum-mcp/dist/index.js");
const mcpEntry = process.env.COREBRUM_MCP_JS || defaultMcp;

if (!existsSync(mcpEntry)) {
  console.error(
    "Missing MCP bundle:",
    mcpEntry,
    "\nBuild: (cd corebrum/contrib/corebrum-mcp && npm install && npm run build)",
  );
  process.exit(1);
}

const child = spawn(process.execPath, [mcpEntry], {
  env: { ...process.env, COREBRUM_URL: process.env.COREBRUM_URL || "http://127.0.0.1:6502" },
  stdio: ["pipe", "pipe", "inherit"],
});

const rl = createInterface({ input: child.stdout });
let buf = "";
let nextId = 1;

function send(obj) {
  child.stdin.write(JSON.stringify(obj) + "\n");
}

function waitFor(predicate, timeoutMs = 15000) {
  return new Promise((resolve, reject) => {
    const t = setTimeout(() => reject(new Error("timeout waiting for MCP response")), timeoutMs);
    function onLine(line) {
      let msg;
      try {
        msg = JSON.parse(line);
      } catch {
        return;
      }
      if (predicate(msg)) {
        clearTimeout(t);
        rl.off("line", onLine);
        resolve(msg);
      }
    }
    rl.on("line", onLine);
  });
}

// Some SDK versions may buffer; also handle line-delimited JSON
rl.on("line", (line) => {
  buf = line;
});

try {
  send({
    jsonrpc: "2.0",
    id: nextId++,
    method: "initialize",
    params: {
      protocolVersion: "2024-11-05",
      capabilities: {},
      clientInfo: { name: "corebrum-examples-smoke", version: "0.1.0" },
    },
  });

  const initRes = await waitFor((m) => m.id === 1 && m.result);
  console.log("initialize OK:", JSON.stringify(initRes.result || {}).slice(0, 200));

  send({
    jsonrpc: "2.0",
    method: "notifications/initialized",
  });

  const listId = nextId++;
  send({
    jsonrpc: "2.0",
    id: listId,
    method: "tools/list",
    params: {},
  });

  const toolsRes = await waitFor((m) => m.id === listId && m.result);
  const names = (toolsRes.result?.tools || []).map((t) => t.name);
  console.log("tools/list OK, count=", names.length, names.slice(0, 8).join(", "), names.length > 8 ? "…" : "");

  child.kill("SIGTERM");
  process.exit(0);
} catch (e) {
  console.error("MCP smoke failed:", e.message);
  console.error("Last line:", buf?.slice(0, 500));
  child.kill("SIGKILL");
  process.exit(1);
}
