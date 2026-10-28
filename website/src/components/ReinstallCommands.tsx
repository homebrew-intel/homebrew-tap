import type { ReactNode } from "react";
import type { Bottle } from "@site/src/lib/bottle";
import { dependencyMap, installOrder, migrationCommands } from "@site/src/lib/migration";
import Copyable from "./Copyable";
import styles from "./BottleList.module.css";

type Props = { names: Iterable<string>; bottles: readonly Bottle[] };

// The commands that switch installed core kegs of `names` to the tap,
// dependencies first, shared by the picker and the Brewfile migration.
export default function ReinstallCommands({ names, bottles }: Props): ReactNode {
  const deps = dependencyMap(bottles);
  const requested = new Set(names);
  const added = installOrder(requested, deps).filter((name) => !requested.has(name));
  return (
    <>
      <Copyable command={migrationCommands(requested, deps)} />
      {added.length > 0 && (
        <p className={styles.note}>
          Includes their tap dependencies, reinstalled first: {added.join(", ")}.
        </p>
      )}
      <p className={styles.note}>
        A keg you built with <code>--build-bottle</code> keeps building on{" "}
        <code>reinstall</code>. Switch it with <code>brew uninstall</code> and
        then <code>brew install macos-intel/tap/&lt;name&gt;</code>.
      </p>
    </>
  );
}
