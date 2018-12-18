#!/usr/bin/env bash
# The script list display resolutions of a single monitor by using xrandr.
# It finds the highest resolution.

RES_LIST=$(xrandr | grep "^ *[0-9]*x[0-9]* *[0-9]*\.[0-9]*")
IFS=$'\n'
x_max=0; y_max=0
for res in $RES_LIST; do
  x_res=$(echo $res | awk '{print $1}' | awk -F'x' '{print $1}')
  y_res=$(echo $res | awk '{print $1}' | awk -F'x' '{print $2}')
  printf "X:%s Y:%s\n" "$x_res" "$y_res"
# Find the highest available resolution from xrandr.
  if [ $((x_res*y_res)) -gt $((x_max*y_max)) ]; then
    x_max=$x_res
    y_max=$y_res
  fi
done
printf "The heighest resolution: %sx%s\n" $x_max $y_max
unset IFS

# Regex to find video outputs in xrandr output.
regex='^[A-Za-z]*-[0-9]*'
video_output=$(xrandr | grep "$regex" | awk '{print $1}')
