#!/bin/sh
# What tmux runs. The base already starts tmux in the working directory (the
# cloned repo when the agent sets spec.repository, else /workspace), so the CLI
# opens straight into the project. Config lives under $COPILOT_HOME, set by
# runtime.json and written by `coding-runtime seed`.
#
# Trust the working directory up front. Otherwise the CLI opens on a "Do you
# trust the files in this folder?" dialog that eats the first keystrokes, and
# this folder is the one the operator provisioned for this agent, so the
# question has only one sensible answer. The only place the CLI honours this is
# `trustedFolders` in its own config.json — not settings.json, not
# --allow-all-paths — and it rewrites that file with `//` comments, which the
# base's strict-JSON seed writer would quarantine on every boot. So the emitter
# stays out of it, and this writes it only when it does not exist yet: the CLI
# keeps the key when it rewrites the file.
#
# Placeholder until #1: no provider wiring and no resume of a previous session
# after the agent sleeps and wakes.
set -eu

config="$COPILOT_HOME/config.json"
if [ ! -e "$config" ]; then
    mkdir -p "$COPILOT_HOME"
    node -e 'process.stdout.write(JSON.stringify({ trustedFolders: [process.cwd()] }) + "\n")' > "$config"
fi

exec copilot "$@"
