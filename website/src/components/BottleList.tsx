import { useState, type ReactNode } from "react";
import useBottles from "@site/src/hooks/useBottles";
import styles from "./BottleList.module.css";

const RELEASES_URL = "https://github.com/macos-intel/homebrew-tap/releases";

export default function BottleList(): ReactNode {
  const state = useBottles();
  const [query, setQuery] = useState("");

  if (state.status === "failed") {
    return (
      <p className={styles.count}>
        Bottle list unavailable. See the <a href={RELEASES_URL}>releases</a>.
      </p>
    );
  }

  const bottles = state.status === "ready" ? state.bottles : [];
  const needle = query.trim().toLowerCase();
  const shown = bottles.filter((bottle) => bottle.name.toLowerCase().includes(needle));

  return (
    <>
      <div className={styles.toolbar}>
        <input
          className={styles.filter}
          type="search"
          placeholder="Filter, e.g. python"
          aria-label="Filter bottles"
          value={query}
          onChange={(event) => setQuery(event.target.value)}
        />
        <p className={styles.count} aria-live="polite">
          {state.status === "loading"
            ? "Loading bottles…"
            : `${bottles.length} formulae with Intel Sequoia bottles`}
        </p>
      </div>
      <ul className={styles.grid}>
        {shown.map((bottle) => (
          <li key={bottle.name}>
            <a className={styles.bottle} href={bottle.url}>
              <span>{bottle.name}</span>
              <span className={styles.version}>{bottle.version}</span>
            </a>
          </li>
        ))}
        {state.status === "ready" && shown.length === 0 && (
          <li className={styles.empty}>
            No bottle matches “{query}”. It may still build from source.
          </li>
        )}
      </ul>
    </>
  );
}
