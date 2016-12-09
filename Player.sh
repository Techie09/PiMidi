#!/bin/bash

#Written by Ryan King
#Script Description
#
#This script is written to manage a list of midi files and information and to process them much like a music player.

#How to use this script
#
#bash playlist.sh [filePath] [test_enabled] [images_enabled] [loop_enabled] [shuffle_enabled]
#
# FilePath
#   Used to load all the midis that will be played. formatted in file as [filePath] [description] [imagePath]
#
# test_enabled
#   Used to switch output from GPIO to Audio Jack. useful for testing script functionality.
#
# images_enabled
#   Used to determine if Images should be displayed
#
# loop_enabled
#   Used to determine if playlist should loop
#
# shuffle_enabled
#   Used to determine if playlist should shuffle

#file path for playlist required to run script
if [-z "$1"] 
then
    echo "Error: playlist is required to fun script." 
    return 
fi

test_enabled = $2
images_enabled = $3
loop_enabled = $4
shuffle_enabled = $5

if [-z "$2"] then test_enabled = 0 fi #may change to playback_Mode and offer additional support (timidity, floppymusic, both, script other)
if [-z "$3"] then images_enabled = 0 fi #may change this to a script, or config file to support versatility with vim. (bmp vs ASCII, animated?)
if [-z "$4"] then loop_enabled = 0 fi
if [-z "$5"] then shuffle_enabled = 0 fi

#read from file a list of songs and descriptions.
declare -a midis
mapfile -t midis < $1

#get length of midis array
mLen=${#midis[@]}

#if no records found when mapping file to array, exit script
if(mLen <= 0) then return fi

if(shuffle_enabled) then shuffleMidis fi
if(!loop_enabled) then displayPlaylist fi

PlayAllMidis

while (loop_enabled)
do
    if(shuffle_enabled) then shuffleMidis fi
    PlayAllMidis
done

#---------------
# End of Script
#---------------

shuffleMidis() {
   local i tmp size max rand

   # $RANDOM % (i+1) is biased because of the limited range of $RANDOM
   # Compensate by using a range which is a multiple of the array size.
   size=${#midis[*]}
   max=$(( 32768 / size * size ))

   for ((i=size-1; i>0; i--)); do
      while (( (rand=$RANDOM) >= max )); do :; done
      rand=$(( rand % (i+1) ))
      tmp=${midis[i]} midis[i]=${midis[rand]} midis[rand]=$tmp
   done
}

displayPlaylist() {
    #loop through and display descriptions
    echo "Playlist found $mLen songs!"
    echo "*---------------------*"
    echo "Test Enabled    $test_enabled"
    echo "Images Enabled  $images_enabled"
    echo "Loop Enabled    $loop_enabled"
    echo "Shuffle Enabled $shuffle_enabled"
    echo "*---------------------*"
    for i in "${midis[@]}"
    do
            declare -a midi=($i)
            echo ${midi[1]}
    done

    sleep 5
}

playAllMidis() {
    #loop through each play each song
    for i in "${midis[@]}"
    do
          PlayMidi  $i
    done
}

playMidi() { #arguments: $1 = midi record
    if [-z "$1"] then return fi
    
    declare -a midi=($1)
    mFilePath = ${midi[0]}
    mDescription = ${midi[1]}
    mImage = ${midi[2]}

    if(images_enabled && [-z !$mImage]) 
    then
        fim $mImage

        if(test_enabled)
        then
            timidity $mFilePath &
        else
            ./floppymusic $mFilePath &
        fi
    else
        if(test_enabled)
        then
            echo "Now Playing: $mDescription"
            timidity $mFilePath
        else
            echo "Now Playing: $mDescription"
            ./floppymusic $mFilePath
        fi
    fi

    
}