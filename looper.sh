#!/bin/bash

# usage: loop.sh <path_to_loop_profile>
# ex: loop.sh astair-intro.txt

stty -echoctl # hide ^C

function debug {
    if [[  "$DEBUG" != "" ]] ; then
        echo "$1"
    fi
}

function tell_spotify_to {
    cmd="osascript -e \"tell application \\\"Spotify\\\" to $1\""
    debug "Executing : $cmd"
    output=`eval $cmd`
}

function control_c {
    tell_spotify_to "pause"
    tell_spotify_to "player position"
    START_SEC=${output%.*}
    echo "Press any key to resume playing or Ctrl-C to exit"
    read -n 1
    echo -e '\b '
    tell_spotify_to "play"
}

function to_secs() {
    secs=$((10#${1#*:}))
    mins=$((10#${1%:*}))
    [ $secs -eq $mins ] && { echo $secs; return; }
    echo $(( 60 * $mins + $secs ))
}

read TRACK_URI START_POS END_POS < "$1"
START_SEC=$(to_secs $START_POS)
ORIG_START=${START_SEC}
END_SEC=$(to_secs $END_POS)

echo "Looping $1"
echo "Track `echo $TRACK_URI | sed s/spotify:/spotify:\\\\/\\\\//`"
echo "From $START_POS to $END_POS"

tell_spotify_to "get sound volume"

# it seems volume always decrease by 1 when rerunning
CURRENT_VOLUME=$(($output+1))

debug "Current volume $CURRENT_VOLUME"

trap control_c SIGINT
trap control_c SIGTERM

tell_spotify_to "set sound volume to 0"
tell_spotify_to "play track \\\"$TRACK_URI\\\""

while [ 1 ]
do
    SEC_DIFF="$(($END_SEC-$START_SEC))"
    debug "Diff position $SEC_DIFF"
    tell_spotify_to "set player position to $START_SEC"
    tell_spotify_to "set sound volume to $CURRENT_VOLUME"
    sleep $SEC_DIFF
    [ $? -eq 0 ] && START_SEC=$ORIG_START
done
