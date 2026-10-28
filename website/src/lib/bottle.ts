// Shape written by scripts/bottles.sh: one entry per formula. `deps` lists
// the formula's tap runtime dependencies and `aliases` the core aliases the
// tap mirrors in Aliases/, both by bare name.
export type Bottle = {
  name: string;
  version: string;
  url: string;
  deps: string[];
  aliases: string[];
};

export const TAP = "macos-intel/tap";
