#!/usr/bin/env bash

# Sourced helper shared by the scripts that run on the build host: the Homebrew
# host safeguards, the no-secrets guard, the builder cache and the
# pending-restore marker. build-formula.sh and pour-formula.sh write the marker
# (the full name of the keg they uninstalled) before the uninstall and delete it
# once that keg is back, so a job killed mid-restore leaves it behind for the
# next run.sh or pour.sh to reinstall. Long brew commands run through
# run_brew, in a process group of their own recorded in the brew-pid marker:
# the Actions runner signals only the job's processes it tracks, and brew drops
# the variable it tracks them by, so a brew left behind by a killed job would
# keep building and hold its formula locks. The caller defines log().
# Must stay compatible with macOS /bin/bash 3.2.

# Host safeguards: never update, clean up, autoremove, upgrade or rebuild
# dependents. Without NO_AUTOREMOVE, removing a half-installed keg also
# uninstalls the dependencies it just pulled in.
export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_AUTOREMOVE=1
export HOMEBREW_NO_INSTALL_CLEANUP=1
export HOMEBREW_NO_INSTALL_UPGRADE=1
export HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK=1

# shellcheck disable=SC2034 # read by the scripts that source this file
readonly NAME_PATTERN='^[a-z0-9][a-z0-9@._+-]*$'
readonly builder_cache="${BUILDER_CACHE:-${HOME}/Library/Caches/homebrew-intel-builder}"
# shellcheck disable=SC2034 # read by the scripts that source this file
readonly pending_restore="${builder_cache}/pending-restore"
readonly brew_pid_file="${builder_cache}/brew-pid"
brew_pid=""

# Formula code (install, test) runs as this user and can read the environment
# of every ancestor process (`ps -E`), so a token here could be stolen and
# shipped inside a public bottle. The host jobs get none; refuse if one leaks in.
refuse_secrets() {
  local secret
  for secret in GH_TOKEN GITHUB_TOKEN PRIVATE_GH_TOKEN
  do
    if [[ -n "${!secret:-}" ]]
    then
      log "refusing to start: ${secret} is set; no token may reach the build host"
      exit 2
    fi
  done
}

# write_atomically <path> <line>: a kill never leaves a half-written file.
write_atomically() {
  mkdir -p "$(dirname "$1")"
  printf '%s\n' "$2" >"$1.tmp"
  mv -f "$1.tmp" "$1"
}

# install_keg <full name>: a tap name may resolve to a just-failed formula (the
# run's checkout), so a failed tap install falls back to the core formula of the
# same name. Returns non-zero when nothing could be installed.
install_keg() {
  local full_name="$1" short_name="${1##*/}"
  run_brew restore install "${full_name}" && return 0
  if [[ "${full_name}" == */* ]]
  then
    log "could not install ${full_name}; falling back to core ${short_name}"
    run_brew restore install "${short_name}" && return 0
  fi
  return 1
}

# run_brew <install|restore> <brew argument>...: runs brew in its own process
# group and records "<pid> <phase>" in the brew-pid marker while it runs. A
# trapped signal interrupts the wait, so the caller's trap can stop_brew.
run_brew() {
  local phase="$1" status=0
  shift
  set -m
  brew "$@" &
  brew_pid=$!
  set +m
  write_atomically "${brew_pid_file}" "${brew_pid} ${phase}"
  wait "${brew_pid}" || status=$?
  rm -f "${brew_pid_file}"
  brew_pid=""
  return "${status}"
}

group_alive() {
  kill -0 -- "-$1" 2>/dev/null
}

# kill_brew_group <pid>: TERM to the group, KILL if it outlives the grace.
kill_brew_group() {
  local group="$1" waited=0
  kill -TERM -- "-${group}" 2>/dev/null || return 0
  while group_alive "${group}"
  do
    if [[ "${waited}" -ge 30 ]]
    then
      kill -KILL -- "-${group}" 2>/dev/null || true
      return 0
    fi
    sleep 1
    waited=$((waited + 1))
  done
}

# For the INT and TERM traps: stops the brew run_brew started, whole tree.
stop_brew() {
  [[ -n "${brew_pid}" ]] || return 0
  log "stopping brew (process group ${brew_pid})"
  kill_brew_group "${brew_pid}"
  rm -f "${brew_pid_file}"
  brew_pid=""
}

# Runs one job at a time, so a brew group still alive at a job's start was
# left by a killed one. A restore gets BUILDER_STALE_WAIT seconds (default 20
# minutes) to finish; anything else is stopped at once, and the pending-restore
# marker then redoes whatever it left undone.
reap_stale_brew() {
  [[ -f "${brew_pid_file}" ]] || return 0
  local group phase waited=0 limit="${BUILDER_STALE_WAIT:-1200}"
  read -r group phase <"${brew_pid_file}" || true
  if [[ "${group}" =~ ^[0-9]+$ && "${group}" -gt 1 ]]
  then
    while [[ "${phase}" = restore && "${waited}" -lt "${limit}" ]] && group_alive "${group}"
    do
      [[ "${waited}" -gt 0 ]] || log "waiting for a previous job's brew restore (process group ${group})"
      sleep 5
      waited=$((waited + 5))
    done
    if group_alive "${group}"
    then
      log "stopping brew left by a previous job (process group ${group}, ${phase:-unknown})"
      kill_brew_group "${group}"
    fi
  fi
  rm -f "${brew_pid_file}"
}

# Reinstalls the keg an interrupted job left uninstalled, before anything
# else; stops the job, Taps link untouched, when that fails.
recover_pending_restore() {
  [[ -f "${pending_restore}" ]] || return 0
  local full_name
  full_name="$(cat "${pending_restore}")"
  log "reinstalling ${full_name}, left uninstalled by an interrupted build"
  # install_keg checks each brew install itself (tap, then core fallback) and its
  # failure is handled below, so errexit is not needed inside it.
  # shellcheck disable=SC2310
  if [[ "${full_name}" =~ ^([a-z0-9-]+/[a-z0-9-]+/)?[a-z0-9][a-z0-9@._+-]*$ ]] &&
     install_keg "${full_name}"
  then
    rm -f "${pending_restore}"
    return 0
  fi
  log "could not reinstall '${full_name}'; reinstall it by hand and delete ${pending_restore}"
  exit 1
}
