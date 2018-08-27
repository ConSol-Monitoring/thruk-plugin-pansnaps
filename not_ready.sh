#!/bin/sh

convert -size 1792x1024 xc:White \
    -gravity Center \
    -weight 700 \
    -pointsize 200 \
    -annotate 0 "NOT\nREADY\nYET" not_ready.jpg
