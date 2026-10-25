import { useEffect, useState } from "react";
import useBaseUrl from "@docusaurus/useBaseUrl";

// Shape written by scripts/bottles.sh: one entry per formula.
export type Bottle = { name: string; version: string; url: string };

export type BottlesState =
  | { status: "loading" }
  | { status: "ready"; bottles: Bottle[] }
  | { status: "failed" };

// bottles.json is fetched once per page load and shared by every caller, so
// the bottle list and the mascot never request it twice.
let request: Promise<Bottle[]> | undefined;

function fetchBottles(source: string): Promise<Bottle[]> {
  request ??= fetch(source)
    .then((response) => {
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      return response.json() as Promise<Bottle[]>;
    })
    .then((bottles) => bottles.sort((a, b) => a.name.localeCompare(b.name)));
  return request;
}

export default function useBottles(): BottlesState {
  const source = useBaseUrl("/bottles.json");
  const [state, setState] = useState<BottlesState>({ status: "loading" });

  useEffect(() => {
    let active = true;
    fetchBottles(source)
      .then((bottles) => active && setState({ status: "ready", bottles }))
      .catch((error: unknown) => {
        console.error("Could not load bottles.json", error);
        if (active) setState({ status: "failed" });
      });
    return () => {
      active = false;
    };
  }, [source]);

  return state;
}
