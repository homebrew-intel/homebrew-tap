import { describe, expect, test } from "bun:test";
import {
  groupNames,
  groupState,
  initialOf,
  restoreSelection,
  serializeSelection,
  shownNames,
  toggleGroup,
  toggleName,
} from "./selection";

const names = ["zstd", "go", "gh", "7zip", "git"];

describe("groupNames", () => {
  test("groups by initial, digits under #, only initials that occur", () => {
    expect(groupNames(names, "")).toEqual([
      { initial: "#", names: ["7zip"] },
      { initial: "G", names: ["gh", "git", "go"] },
      { initial: "Z", names: ["zstd"] },
    ]);
    expect(initialOf("Cmake")).toBe("C");
  });

  test("keeps only matching names and drops emptied groups", () => {
    expect(groupNames(names, " GI ")).toEqual([{ initial: "G", names: ["git"] }]);
    expect(groupNames(names, "nothing")).toEqual([]);
  });
});

describe("groupState", () => {
  test("is tri-state", () => {
    expect(groupState(["a", "b"], new Set())).toBe("none");
    expect(groupState(["a", "b"], new Set(["a", "x"]))).toBe("some");
    expect(groupState(["a", "b"], new Set(["a", "b"]))).toBe("all");
  });
});

describe("toggles", () => {
  test("toggleName adds then removes without mutating", () => {
    const start = new Set(["a"]);
    expect([...toggleName(start, "b")].sort()).toEqual(["a", "b"]);
    expect([...toggleName(start, "a")]).toEqual([]);
    expect([...start]).toEqual(["a"]);
  });

  test("toggleGroup fills a partial group, clears a full one, keeps others", () => {
    const partial = toggleGroup(new Set(["a", "other"]), ["a", "b"]);
    expect([...partial].sort()).toEqual(["a", "b", "other"]);
    expect([...toggleGroup(partial, ["a", "b"])]).toEqual(["other"]);
  });

  test("toggleGroup only touches the names it is given (the visible ones)", () => {
    expect([...toggleGroup(new Set(), ["git"])]).toEqual(["git"]);
  });
});

describe("select all", () => {
  test("shownNames covers every group in list order", () => {
    expect(shownNames(groupNames(names, ""))).toEqual(["7zip", "gh", "git", "go", "zstd"]);
  });

  test("shownNames follows the filter, so All only touches matches", () => {
    const shown = shownNames(groupNames(names, "g"));
    expect([...toggleGroup(new Set(["zstd"]), shown)].sort()).toEqual(["gh", "git", "go", "zstd"]);
  });
});

describe("saved selection", () => {
  const known = new Set(["cmake", "git"]);

  test("round-trips and drops unknown names", () => {
    const saved = serializeSelection(new Set(["git", "cmake", "gone"]));
    expect([...restoreSelection(saved, known)].sort()).toEqual(["cmake", "git"]);
  });

  test("ignores missing or malformed values", () => {
    expect(restoreSelection(null, known).size).toBe(0);
    expect(restoreSelection("{not json", known).size).toBe(0);
    expect(restoreSelection('{"git":1}', known).size).toBe(0);
    expect(restoreSelection('["git", 3]', known)).toEqual(new Set(["git"]));
  });
});
