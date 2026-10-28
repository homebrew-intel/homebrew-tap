import { useState, type ReactNode } from "react";
import styles from "./Copyable.module.css";

// `prompt` off shows file contents (a Brewfile) without the "$ " prompt,
// in a well that scrolls instead of growing with the file.
type Props = { command: string; prompt?: boolean };

// brew.sh's copyable command: a "$ " prompt per line and a copy button
// joined to the right edge of the code well.
export default function Copyable({ command, prompt = true }: Props): ReactNode {
  const [copied, setCopied] = useState(false);

  async function copy(): Promise<void> {
    try {
      await navigator.clipboard.writeText(command);
      setCopied(true);
      setTimeout(() => setCopied(false), 1600);
    } catch (error: unknown) {
      console.error("Clipboard write failed", error);
    }
  }

  return (
    <div className={styles.copyable}>
      <pre className={prompt ? styles.code : `${styles.code} ${styles.file}`}>
        {/* Lines repeat in a file (blank ones at least), so key by index. */}
        {command.split("\n").map((line, index) => (
          <code key={index}>{line || " "}</code>
        ))}
      </pre>
      <button
        type="button"
        className={styles.button}
        onClick={copy}
        aria-label={copied ? "Copied" : "Copy to clipboard"}
        title={copied ? "Copied" : "Copy to clipboard"}
      >
        {copied ? "✓" : "⧉"}
      </button>
    </div>
  );
}
