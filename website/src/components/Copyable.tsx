import { useState, type ReactNode } from "react";
import styles from "./Copyable.module.css";

type Props = { command: string };

// brew.sh's copyable command: a "$ " prompt per line and a copy button
// joined to the right edge of the code well.
export default function Copyable({ command }: Props): ReactNode {
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
      <pre className={styles.code}>
        {command.split("\n").map((line) => (
          <code key={line}>{line}</code>
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
