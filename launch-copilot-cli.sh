#!/bin/sh
# What tmux runs. The base already starts tmux in the working directory (the
# cloned repo when the agent sets spec.repository, else /workspace), so the CLI
# opens straight into the project. Config lives under $COPILOT_HOME, set by
# runtime.json and written by `coding-runtime seed`.
#
# Placeholder until #1: no provider wiring and no resume of a previous session
# after the agent sleeps and wakes.
set -eu

exec copilot "$@"
