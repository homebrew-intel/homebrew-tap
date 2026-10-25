---
sidebar_position: 2
---

# How it works

Intel macOS is Tier 3 in Homebrew: homebrew-core no longer publishes Intel
bottles. This tap fills that gap for an explicit, growing list of formulae.

## Generated formulae

Most formulae in the tap are generated from homebrew-core and are never
edited by hand. The tap only adds Intel `sequoia` bottles, built on Intel
runners and published as GitHub releases.

## Patched formulae

Some formulae were removed, disabled or restricted to arm64 in core even
though the software still works on Intel. The tap can carry those with a
small reviewed patch on top of core's version.

## Lifetime

Homebrew plans to stop running on Intel in or after September 2027. This
project ends then, unless a separate decision extends it.

It is not affiliated with or endorsed by Homebrew.
