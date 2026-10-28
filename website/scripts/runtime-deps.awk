# Prints "<formula>\t<dep>" for every `depends_on "macos-intel/tap/<dep>"`
# in the formula files given that applies at runtime on Intel Sequoia, for
# scripts/bottles.sh. Build and test dependencies are left out: switching a
# keg never needs them. Blocks that never apply there (on_linux, on_arm,
# head, on_<macos> :or_older, on_system without _or_newer) are skipped up to
# the `end` at their own indentation, which holds because rendered formulae
# follow core's rubocop layout.
FNR == 1 {
  skip = -1
  name = FILENAME
  sub(/.*\//, "", name)
  sub(/\.rb$/, "", name)
}

{
  match($0, /^ */)
  indent = RLENGTH
  if (skip >= 0) {
    if (indent == skip && $0 ~ /^ *end *$/) skip = -1
    next
  }
  if ($0 ~ /^ *(on_linux|on_arm|head) do *$/ ||
      ($0 ~ /^ *on_[a-z]+ :or_older do/ && $0 !~ /on_(sequoia|tahoe) /) ||
      ($0 ~ /^ *on_system / && $0 !~ /_or_newer/)) {
    skip = indent
    next
  }
  code = $0
  sub(/#.*/, "", code)
  if (code !~ /^ *depends_on "macos-intel\/tap\/[^"]+"/) next
  if (code ~ /=>/ && code ~ /:(build|test)/) next
  dep = code
  sub(/^ *depends_on "macos-intel\/tap\//, "", dep)
  sub(/".*/, "", dep)
  printf "%s\t%s\n", name, dep
}
