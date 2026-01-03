import GLib from "gi://GLib";
import * as AstalFile from "astal/file";

// Re-export what ConfigManager imports
export const Gio = (AstalFile as any).Gio;
export const readFile = (AstalFile as any).readFile;
export const monitorFile = (AstalFile as any).monitorFile;

const _realWriteFile: any = (AstalFile as any).writeFile;

const ALWAYS = (GLib.getenv("HYPRPANEL_LOG_WRITES") ?? "1") === "1"; // default ON
const FILTER = GLib.getenv("HYPRPANEL_LOG_WRITE_FILTER") ?? "";

function shouldLog(path: string): boolean {
  if (!path) return false;
  if (FILTER && !path.includes(FILTER)) return false;
  return ALWAYS;
}

function nowStamp(): string {
  const dt = new Date();
  const pad = (n: number, w = 2) => String(n).padStart(w, "0");
  return (
    `${dt.getFullYear()}${pad(dt.getMonth() + 1)}${pad(dt.getDate())}-` +
    `${pad(dt.getHours())}${pad(dt.getMinutes())}${pad(dt.getSeconds())}-` +
    `${pad(dt.getMilliseconds(), 3)}`
  );
}

function safeBasename(path: string): string {
  const base = path.split("/").filter(Boolean).pop() ?? "unknown";
  return base.replace(/[^a-zA-Z0-9._-]+/g, "_");
}

function dumpAttempt(path: string, contents: string, reason: string) {
  try {
    const dir = "/tmp/hyprpanel-write-attempts";
    GLib.mkdir_with_parents(dir, 0o755);

    const stamp = nowStamp();
    const base = safeBasename(path);
    const outBase = `${dir}/${stamp}-${base}`;

    // payload
    (GLib as any).file_set_contents(outBase + ".attempt", contents ?? "");

    // metadata
    const meta = {
      originalPath: path,
      reason,
      dumpedAt: new Date().toISOString(),
      size: contents?.length ?? 0,
    };
    (GLib as any).file_set_contents(
      outBase + ".meta.json",
      JSON.stringify(meta, null, 2)
    );
  } catch (e) {
    console.error(`[hyprpanel][write-wrap] dumpAttempt failed: ${String(e)}`);
  }
}

// Wrapped writeFile used by config manager
export function writeFile(path: string, contents: string, ...rest: any[]) {
  const log = shouldLog(path);

  if (log) {
    console.error(
      `[hyprpanel][write-wrap] writeFile -> ${path} (${
        contents?.length ?? 0
      } chars)`
    );
    // Dump every attempt so you can diff even if it *succeeds*
    dumpAttempt(path, contents ?? "", "writeFile called (pre-write dump)");
  }

  try {
    const ret = _realWriteFile(path, contents, ...rest);
    if (log) console.error(`[hyprpanel][write-wrap] writeFile OK -> ${path}`);
    return ret;
  } catch (e) {
    console.error(
      `[hyprpanel][write-wrap] writeFile FAIL -> ${path}: ${String(e)}`
    );
    dumpAttempt(path, contents ?? "", `writeFile failed: ${String(e)}`);
    throw e;
  }
}
