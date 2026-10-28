import { useMemo, useState, type ChangeEvent, type ReactNode } from "react";
import useBottles from "@site/src/hooks/useBottles";
import type { Bottle } from "@site/src/lib/bottle";
import { migrateBrewfile, tapIndex, type BrewfileMigration as Result } from "@site/src/lib/brewfile";
import Copyable from "./Copyable";
import ReinstallCommands from "./ReinstallCommands";
import styles from "./Brewfile.module.css";

// A Brewfile is a short text file; anything far larger is not one, and
// reading it would only stall the tab.
const MAX_BYTES = 512 * 1024;

// Saves the rewritten file under the name brew bundle looks for.
function download(text: string): void {
  const url = URL.createObjectURL(new Blob([text], { type: "text/plain" }));
  const link = document.createElement("a");
  link.href = url;
  link.download = "Brewfile";
  link.click();
  URL.revokeObjectURL(url);
}

// Loads or takes a pasted Brewfile and rewrites it for the tap. Everything
// happens in this tab: FileReader reads the file locally and nothing is
// sent anywhere, which the UI says, since a Brewfile lists what a machine
// runs.
export default function BrewfileMigration(): ReactNode {
  const state = useBottles();
  const bottles = state.status === "ready" ? state.bottles : [];
  const [source, setSource] = useState("");
  const [error, setError] = useState("");
  const result = useMemo(
    () => (source.trim() ? migrateBrewfile(source, tapIndex(bottles)) : undefined),
    [source, bottles],
  );

  function load(event: ChangeEvent<HTMLInputElement>): void {
    const file = event.target.files?.[0];
    // Reset so picking the same file again still fires a change.
    event.target.value = "";
    if (!file) return;
    if (file.size > MAX_BYTES) {
      setError(`${file.name} is over 512 KB; that is not a Brewfile.`);
      return;
    }
    const reader = new FileReader();
    reader.onload = () => {
      setError("");
      setSource(typeof reader.result === "string" ? reader.result : "");
    };
    reader.onerror = () => setError(`Could not read ${file.name}.`);
    reader.readAsText(file);
  }

  return (
    <div className={styles.migration}>
      <p>
        Load or paste a Brewfile to switch its entries to the tap. It stays in
        your browser: the file is read and rewritten on this page and never
        uploaded.
      </p>
      <div className={styles.inputs}>
        <label className={styles.upload}>
          Load a Brewfile
          <input type="file" className={styles.fileInput} onChange={load} />
        </label>
        {source && (
          <button type="button" className={styles.upload} onClick={() => setSource("")}>
            Clear
          </button>
        )}
      </div>
      {error && <p role="alert" className={styles.error}>{error}</p>}
      <textarea
        className={styles.source}
        aria-label="Brewfile contents"
        placeholder={'tap "homebrew/bundle"\nbrew "cmake"\nbrew "pkg-config"'}
        spellCheck={false}
        rows={6}
        value={source}
        onChange={(event) => setSource(event.target.value)}
      />
      {result && <MigrationResult result={result} bottles={bottles} />}
    </div>
  );
}

type ResultProps = { result: Result; bottles: readonly Bottle[] };

function MigrationResult({ result, bottles }: ResultProps): ReactNode {
  if (result.changes.length === 0) {
    return <p className={styles.status}>Nothing to change: no entry names a tap formula.</p>;
  }
  return (
    <div aria-live="polite">
      <p className={styles.status}>
        {result.changes.length} {result.changes.length === 1 ? "line" : "lines"} changed:
      </p>
      <pre className={styles.diff}>
        {result.changes.map((change) => (
          <span key={change.line} className={styles.change}>
            <span className={styles.lineNumber}>line {change.line}</span>
            {change.before !== undefined && <del>{`- ${change.before}`}</del>}
            <ins>{`+ ${change.after}`}</ins>
          </span>
        ))}
      </pre>
      {result.warnings.map((warning) => (
        <p key={warning} role="alert" className={styles.error}>{warning}</p>
      ))}
      <div className={styles.fileHeader}>
        <span>Rewritten Brewfile</span>
        <button type="button" className={styles.upload} onClick={() => download(result.text)}>
          Download Brewfile
        </button>
      </div>
      <Copyable command={result.text} prompt={false} />
      {result.migrated.length > 0 && (
        <>
          <p className={styles.status}>Switch the kegs you already have:</p>
          <ReinstallCommands names={result.migrated} bottles={bottles} />
        </>
      )}
    </div>
  );
}
