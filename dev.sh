#!/usr/bin/env bash

tmux new-session -s api-browser.nvim \; \
  send-keys "n" C-m \; \
  new-window \; \
  send-keys "make mock-dev" C-m \; \
  split-window -fh \; \
  send-keys "make mock-remote" C-m \; \
  next-window
