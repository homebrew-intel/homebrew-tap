import { useEffect, useRef, type ReactNode } from "react";
import type { Bottle } from "@site/src/lib/bottle";
import { groupState } from "@site/src/lib/selection";
import styles from "./BottleList.module.css";

type Props = {
  initial: string;
  bottles: Bottle[];
  expanded: boolean;
  // Undefined while a filter forces the group open.
  onToggleExpanded?: () => void;
  selected: ReadonlySet<string>;
  onToggleName: (name: string) => void;
  onToggleGroup: (names: string[]) => void;
};

// One letter of the list: a header with a tri-state checkbox for the
// formulae it shows and a button that opens or closes the cards.
export default function BottleGroup(props: Props): ReactNode {
  const { initial, bottles, expanded, onToggleExpanded, selected } = props;
  const names = bottles.map((bottle) => bottle.name);
  const state = groupState(names, selected);
  const checkbox = useRef<HTMLInputElement>(null);
  const listId = `bottles-${initial === "#" ? "digits" : initial}`;

  // "indeterminate" has no HTML attribute; it can only be set as a property.
  useEffect(() => {
    if (checkbox.current) checkbox.current.indeterminate = state === "some";
  }, [state]);

  const picked = names.filter((name) => selected.has(name)).length;
  return (
    <section className={styles.group} aria-label={`Formulae starting with ${initial}`}>
      <div className={styles.groupHeader}>
        <input
          ref={checkbox}
          type="checkbox"
          className={styles.check}
          checked={state === "all"}
          onChange={() => props.onToggleGroup(names)}
          aria-label={`Select all ${names.length} shown formulae starting with ${initial}`}
        />
        <button
          type="button"
          className={styles.groupToggle}
          aria-expanded={expanded}
          aria-controls={listId}
          disabled={!onToggleExpanded}
          onClick={onToggleExpanded}
        >
          <span className={styles.initial}>{initial}</span>
          <span className={styles.groupCount}>
            {names.length} {names.length === 1 ? "formula" : "formulae"}
            {picked > 0 && `, ${picked} selected`}
          </span>
          <span className={styles.chevron} aria-hidden="true">
            {expanded ? "▾" : "▸"}
          </span>
        </button>
      </div>
      {expanded && (
        <ul id={listId} className={styles.grid}>
          {bottles.map((bottle) => (
            <li key={bottle.name}>
              <BottleCard bottle={bottle} checked={selected.has(bottle.name)} onToggle={props.onToggleName} />
            </li>
          ))}
        </ul>
      )}
    </section>
  );
}

type CardProps = { bottle: Bottle; checked: boolean; onToggle: (name: string) => void };

// The name toggles the selection; the version stays a link to the release.
// They are siblings, not nested, so a click on the link never toggles.
function BottleCard({ bottle, checked, onToggle }: CardProps): ReactNode {
  return (
    <div className={checked ? `${styles.bottle} ${styles.picked}` : styles.bottle}>
      <label className={styles.pick}>
        <input
          type="checkbox"
          className={styles.check}
          checked={checked}
          onChange={() => onToggle(bottle.name)}
        />
        <span>{bottle.name}</span>
      </label>
      <a className={styles.version} href={bottle.url} aria-label={`${bottle.name} ${bottle.version} release`}>
        {bottle.version}
      </a>
    </div>
  );
}
