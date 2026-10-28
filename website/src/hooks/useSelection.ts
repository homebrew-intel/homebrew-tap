import { useEffect, useState } from "react";
import type { Bottle } from "@site/src/lib/bottle";
import { restoreSelection, serializeSelection } from "@site/src/lib/selection";

const STORAGE_KEY = "homebrew-intel:selection";

export type Selection = {
  selected: ReadonlySet<string>;
  setSelected: (next: ReadonlySet<string>) => void;
};

// The picked formulae, saved in localStorage so they survive a reload.
// Storage can be missing or throw (private windows, blocked site data), so
// every access is guarded and the page then simply forgets on reload. The
// saved list is only read once bottles.json is in, so names that left the
// tap are dropped instead of resurfacing in the commands.
export default function useSelection(bottles: readonly Bottle[] | undefined): Selection {
  const [selected, setSelectedState] = useState<ReadonlySet<string>>(new Set());
  const [restored, setRestored] = useState(false);

  useEffect(() => {
    if (!bottles || restored) return;
    let saved: string | null = null;
    try {
      saved = window.localStorage.getItem(STORAGE_KEY);
    } catch (error: unknown) {
      console.warn("Saved selection unavailable", error);
    }
    setSelectedState(restoreSelection(saved, new Set(bottles.map((bottle) => bottle.name))));
    setRestored(true);
  }, [bottles, restored]);

  function setSelected(next: ReadonlySet<string>): void {
    setSelectedState(next);
    try {
      window.localStorage.setItem(STORAGE_KEY, serializeSelection(next));
    } catch (error: unknown) {
      console.warn("Could not save the selection", error);
    }
  }

  return { selected, setSelected };
}
