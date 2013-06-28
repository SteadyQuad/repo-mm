#!/bin/bash

#set -x

## Variables
# myname: This scripts name.
declare myname="${0##*/}"
# gerrit_host: The gerrit host we can query to get the list of projects.
declare gerrit_host="http://review.cyanogenmod.org"
# git_host: The git url where the source can be downloaded.
declare git_host="http://github.com"
# update_remote: If set to 1, repositories will get their remote updated to the
# git_host before fetching.
declare update_remote=0

# exceptions: array: List of repositories to ignore.
declare -a exceptions
exceptions+=("CyanogenMod/CMStatsServer")
exceptions+=("CyanogenMod/android_device_htc_m7")
exceptions+=("CyanogenMod/android_device_htc_m7wls")

## Utility Functions
# usage: Display usage about the script.
usage()
{
  echo "Usage: ${myname} [-h|--help] <gerrit_host> <git_host>"
  echo "  gerrit_host: default: ${gerrit_host}"
  echo "  git_host: default: ${git_host}"
  echo "  -h | --help: display usage (this)"
  exit 1
}

# info: Output an informational string.
info()
{
  echo -ne "${myname} Info: ${@}\n"
}

# warn: Output a warning string.
warn()
{
  echo -ne "${myname} Warning: ${@}\n"
}

# err: Output an error string and exit with 2.
err()
{
  echo -ne "${myname} Error: ${@}\n"
  exit 2
}

# matchException: Match the input string with the array of exceptions.
# Yes, this could be optimized. Feel free to make this quicker.
matchException()
{
  input="${1}"
  for ignore in "${exceptions[@]}"; do
    if [ x"${ignore}" = x"${input}" ]; then
      return 1
    fi
  done
  return 0
}

## Traps
# If you try to interrupt the script with ^c or ^\, the script doesn't end,
# and the next iteration of git runs. Trap these signals and err out.
trap "err killed by signal" SIGINT SIGTERM SIGQUIT

## Script Argument Processing
# The accepted number of arguments is either 0 1 or 2.
# 0: fall through to defaults of http://review.cyanogenmod.org http://github.com
# 1: usage
# 2: Defined your own gerrit_host and git_host.
if [ $# -ne 0 ]; then
  if [ $# -eq 2 ]; then
    gerrit_host="$1"
    git_host="$2"
  elif [ $# -gt 2 ]; then
    usage
  elif [ x"$1" = x"-h" -o x"$1" = x"--help" ]; then
    usage
  fi
fi

## Main loop
# For each repository managed by the gerrit instance...
for repo in $(curl -s "${gerrit_host}/projects/?d" | \
    tail -n +2 | jshon -k | grep -v '\/\.' | sort); do
  # Ignore repositories that might possibly be discontinued.
  matchException "${repo}"
  if [ $? -eq 1 ]; then
    warn "Skipping exception: ${repo}.git"
    continue
  else
    # If we already have the repository, fetch all.
    if [ -d "${repo}.git" ]; then
      pushd "${repo}.git/" 2>&1 > /dev/null
      if [ $update_remote -eq 1 ]; then
        info "Updating remote to: ${git_host}/${repo}.git"
        git remote set-url origin "${git_host}/${repo}.git"
        [ $? -eq 0 ] || err "Failed to update remote. Exit code: $?"
      fi
      info "Fetching: ${repo}"
      git fetch --all
      [ $? -eq 0 ] || err "Failed to fetch ${repo}. Exit code: $?"
      popd 2>&1 > /dev/null
    # Otherwise, clone a mirror.
    else
      info "Cloning: ${repo}"
      git clone --mirror "${git_host}/${repo}.git" "${repo}.git"
      [ $? -eq 0 ] || err "Failed to clone ${repo}. Exit code: $?"
    fi
  fi
  echo ""
done
