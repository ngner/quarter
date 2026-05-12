#!/usr/bin/env node
import { execSync } from "node:child_process";

const runId = `progress-${Date.now()}`;
const kubeconfig = process.env.KUBECONFIG || "";

function cmd(command) {
  try {
    const stdout = execSync(command, { stdio: ["ignore", "pipe", "pipe"] }).toString();
    return { ok: true, stdout, stderr: "" };
  } catch (error) {
    return {
      ok: false,
      stdout: error.stdout ? error.stdout.toString() : "",
      stderr: error.stderr ? error.stderr.toString() : String(error),
    };
  }
}

function log(hypothesisId, location, message, data) {
  // #region agent log
  fetch("http://127.0.0.1:7566/ingest/73960e6d-4a92-4135-9f4c-97d082308f7b", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-Debug-Session-Id": "218d3c",
    },
    body: JSON.stringify({
      sessionId: "218d3c",
      runId,
      hypothesisId,
      location,
      message,
      data,
      timestamp: Date.now(),
    }),
  }).catch(() => {});
  // #endregion
}

log("H1", "scripts/debug-pattern-progress.mjs:40", "debug probe started", {
  hasKubeconfig: Boolean(kubeconfig),
});

const pattern = cmd(
  "oc get pattern multicloud-gitops-extension -n patterns-operator -o json"
);
log("H2", "scripts/debug-pattern-progress.mjs:46", "pattern fetch result", {
  ok: pattern.ok,
  stderr: pattern.stderr.slice(0, 300),
});

if (pattern.ok) {
  const p = JSON.parse(pattern.stdout);
  log("H2", "scripts/debug-pattern-progress.mjs:53", "pattern spec/status snapshot", {
    gitSpecKeys: Object.keys((p.spec && p.spec.gitSpec) || {}),
    hasValuesFiles: Object.prototype.hasOwnProperty.call(p.spec || {}, "valuesFiles"),
    lastStep: p.status && p.status.lastStep,
    lastError: p.status && p.status.lastError,
  });
}

const explain = cmd("oc explain pattern.spec.gitSpec --recursive");
log("H3", "scripts/debug-pattern-progress.mjs:62", "gitSpec schema snapshot", {
  ok: explain.ok,
  hasOriginRepo: /originRepo/.test(explain.stdout),
  hasTargetRepo: /targetRepo/.test(explain.stdout),
  hasGitRepo: /gitRepo/.test(explain.stdout),
  hasGitBranch: /gitBranch/.test(explain.stdout),
  stderr: explain.stderr.slice(0, 300),
});

const applyDryRun = cmd("oc apply --dry-run=server -f examples/pattern-cr.yaml -o yaml");
log("H4", "scripts/debug-pattern-progress.mjs:72", "server-side dry-run outcome", {
  ok: applyDryRun.ok,
  stderr: applyDryRun.stderr.slice(0, 400),
  stdoutHead: applyDryRun.stdout.slice(0, 220),
});

const patternAfter = cmd(
  "oc get pattern multicloud-gitops-extension -n patterns-operator -o jsonpath='{.status.lastError}{\"|\"}{.status.lastStep}'"
);
log("H5", "scripts/debug-pattern-progress.mjs:81", "post-check pattern status", {
  ok: patternAfter.ok,
  value: patternAfter.stdout.trim(),
  stderr: patternAfter.stderr.slice(0, 300),
});

