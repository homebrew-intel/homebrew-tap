import { useEffect, useRef, type ReactNode } from "react";
import { groupState } from "@site/src/lib/selection";
import styles from "./BottleList.module.css";

type Props = {
  names: string[];
  selected: ReadonlySet<string>;
  onToggle: (names: string[]) => void;
};

// A tri-state checkbox over every formula the list shows, placed above and
// below the groups. Like a group checkbox, with a filter active it only
// changes the matches.
export default function SelectAll({ names, selected, onToggle }: Props): ReactNode {
  const state = groupState(names, selected);
  const checkbox = useRef<HTMLInputElement>(null);

  // "indeterminate" has no HTML attribute; it can only be set as a property.
  useEffect(() => {
    if (checkbox.current) checkbox.current.indeterminate = state === "some";
  }, [state]);

  return (
    <label className={styles.selectAll}>
      <input
        ref={checkbox}
        type="checkbox"
        className={styles.check}
        checked={state === "all"}
        disabled={names.length === 0}
        onChange={() => onToggle(names)}
      />
      All ({names.length} {names.length === 1 ? "formula" : "formulae"} shown)
    </label>
  );
}
