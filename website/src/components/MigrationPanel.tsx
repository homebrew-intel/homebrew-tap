import type { ReactNode } from "react";
import Heading from "@theme/Heading";
import type { Bottle } from "@site/src/lib/bottle";
import { toggleName } from "@site/src/lib/selection";
import ReinstallCommands from "./ReinstallCommands";
import styles from "./BottleList.module.css";

type Props = {
  bottles: readonly Bottle[];
  selected: ReadonlySet<string>;
  onChange: (next: ReadonlySet<string>) => void;
};

// The picked formulae and the commands that switch them to the tap.
export default function MigrationPanel({ bottles, selected, onChange }: Props): ReactNode {
  const names = [...selected].sort();
  return (
    <div className={styles.panel} aria-live="polite">
      <Heading as="h3" className={styles.panelTitle}>
        Switch kegs you already have
      </Heading>
      {names.length === 0 ? (
        <p className={styles.note}>
          Tick the formulae you have installed from core to get the commands
          that move them to the tap. Your picks are kept in this browser.
        </p>
      ) : (
        <>
          <div className={styles.chips}>
            {names.map((name) => (
              <button
                key={name}
                type="button"
                className={styles.chip}
                onClick={() => onChange(toggleName(selected, name))}
                aria-label={`Remove ${name} from the selection`}
              >
                {name} <span aria-hidden="true">×</span>
              </button>
            ))}
            <button type="button" className={styles.action} onClick={() => onChange(new Set())}>
              Clear selection
            </button>
          </div>
          <ReinstallCommands names={names} bottles={bottles} />
        </>
      )}
    </div>
  );
}
