#!/bin/bash

#         # --before-text "%{u#1db954}%{+u}" \
# see man zscroll for documentation of the following parameters
zscroll -l 30 \
        --delay 0.3 \
        --scroll-padding " " \
        --match-command "get_spotify_status --status" \
        --match-text "Playing" "--scroll 1" \
        --match-text "Paused" "--scroll 0" \
        --update-check true "get_spotify_status" &
wait