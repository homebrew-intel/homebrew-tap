import { useState, type ReactNode } from "react";
import useBottles from "@site/src/hooks/useBottles";
import useSelection from "@site/src/hooks/useSelection";
import type { Bottle } from "@site/src/lib/bottle";
import { groupNames, toggleGroup, toggleName } from "@site/src/lib/selection";
import BottleGroup from "./BottleGroup";
import MigrationPanel from "./MigrationPanel";
import styles from "./BottleList.module.css";

const RELEASES_URL = "https://github.com/macos-intel/homebrew-tap/releases";

// The list is grouped by first letter and starts collapsed, so the section
// stays short as the tap grows. Typing a filter opens every group with a
// match and shows only the matches; clearing it returns to the groups the
// user opened by hand.
export default function BottleList(): ReactNode {
  const state = useBottles();
  const bottles = state.status === "ready" ? state.bottles : undefined;
  const { selected, setSelected } = useSelection(bottles);
  const [query, setQuery] = useState("");
  const [open, setOpen] = useState<ReadonlySet<string>>(new Set());

  if (state.status === "failed") {
    return (
      <p className={styles.count}>
        Bottle list unavailable. See the <a href={RELEASES_URL}>releases</a>.
      </p>
    );
  }

  const all = bottles ?? [];
  const byName = new Map(all.map((bottle) => [bottle.name, bottle]));
  const filtering = query.trim() !== "";
  const groups = groupNames(all.map((bottle) => bottle.name), query);
  const allOpen = groups.length > 0 && groups.every((group) => open.has(group.initial));

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
        <button
          type="button"
          className={styles.action}
          disabled={filtering || groups.length === 0}
          onClick={() => setOpen(allOpen ? new Set() : new Set(groups.map((group) => group.initial)))}
        >
          {allOpen ? "Collapse all" : "Expand all"}
        </button>
        <p className={styles.count} aria-live="polite">
          {state.status === "loading"
            ? "Loading bottles…"
            : `${all.length} formulae with Intel Sequoia bottles`}
        </p>
      </div>
      <div className={styles.groups}>
        {groups.map((group) => (
          <BottleGroup
            key={group.initial}
            initial={group.initial}
            bottles={group.names.map((name) => byName.get(name)).filter((bottle): bottle is Bottle => !!bottle)}
            expanded={filtering || open.has(group.initial)}
            onToggleExpanded={filtering ? undefined : () => setOpen(toggleName(open, group.initial))}
            selected={selected}
            onToggleName={(name) => setSelected(toggleName(selected, name))}
            onToggleGroup={(names) => setSelected(toggleGroup(selected, names))}
          />
        ))}
        {state.status === "ready" && groups.length === 0 && (
          <p className={styles.empty}>No bottle matches “{query}”. It may still build from source.</p>
        )}
      </div>
      <MigrationPanel bottles={all} selected={selected} onChange={setSelected} />
    </>
  );
}
