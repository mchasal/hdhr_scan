#!/bin/bash

# hdhr_scan.sh
#
# Simple program to capture screenshot from all channels on an
# older HD HomeRun box. 
# Generates a very simple HTML file to view the results.
#
# Author: Michael Chase-Salerno <mcs@chasal.net>
#
# Prereqs:
#       hdhomerun_config
#       vlc (currently due to ffmpeg issue)
#
######################################################################
# Copyright (C) 2016 Michael Chase-Salerno
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
######################################################################

# Set these values to the proper ones for your HD Home Run
# Use "hdhomerund_config discover" to find them.
ID=101B8CCA # HDHomeRun device ID
T=tuner1 # Tuner to use (use the least popular one)

# Set these to desired values
PMAX=6 # Number of passes to make, set to one more than you want
PAUSE=600 # sleep time in between passes, longer time will spread 
        # out the screencaps for more variety
OUTDIR=~/hdhr_scan/ # Desired output directory

# SHould need to muck about below here....
LOGFILE=$OUTDIR/hdhr_scan.log
OUTFILE=$OUTDIR/index.html

mkdir -p $OUTDIR

# Check for an existing channel scan, or create one
if [[ ! -f $OUTDIR/chanscan.log ]] 
then
    echo "Performing channel scan..."
    hdhomerun_config $ID scan /$T $OUTDIR/chanscan.log
else
    echo "Channel discovery skipped, using existing channel scan file"
fi

echo "Programming scan starting" > $LOGFILE
echo "<body>" > $OUTFILE

# Cleanup anything from a previous run
rm $OUTDIR/CAP* 2>/dev/null
rm $OUTDIR/out.png 2>/dev/null
rm $OUTDIR/out.mpg 2>/dev/null

#Parse channel scan file
P=0
while [ $P -lt $PMAX ]
do
  ((P++))
  echo "Pass: "$P
  while read l
  do
    # Looking for lines that start with "SCANNING" or "PROGRAM"
    al=(${l// / })
    if [[ $l == SCANNING* ]]
    then
        # "SCANNING" indicates a channel, tune the HDHR
        echo $l
        CHANLINE=$l 
        CHAN=${al[1]}
        hdhomerun_config $ID set /$T/channel $CHAN
    fi
    # "PROGRAM" indicates a subchannel, and actual content, but skip encrypted 
    # and control subchannels.
    if [[ $l == PROGRAM* ]] && [[ $l != *encrypted* ]] && [[ $l != *control* ]]
    then
        echo $l
        if [ $P -eq 1 ]
        then
            # Prime the HTML on the first subchannel
            echo -e "<br><hr width=100%>" >>$OUTFILE
            echo -e "<br>"$CHANLINE >>$OUTFILE
            echo -e "\t<br>"$l"<br>" >>$OUTFILE
        fi
        PROG=${al[1]::-1} # Drop the last char
        # Set the HDHR subchannel
        hdhomerun_config $ID set /$T/program $PROG
        sleep 1 # Just to make sure...
        # Now capture 5 seconds of video
        timeout 5 hdhomerun_config $ID save /$T out.mpg >/dev/null 2>&1
        IFNa=$OUTDIR/"CAP_"$CHAN"_"$PROG"_"
        if [ $P -eq 1 ]
        then
            # Create the HTML for all screencaps we're planning on
            p=0
            while [ $p -lt $PMAX ]
            do
                ((p++))
                IFN=$IFNa$p".png"
                echo -e "\t<a href="$IFN"><img src="$IFN" height=250></a>">>$OUTFILE
            done
        fi
        # Generate a filename, and grab a frame from the video
        IFN=$IFNa$P".png"
        vlc out.mpg --video-filter=scene --vout=dummy --aout=dummy --start-time=0 \
        --stop-time=3 --scene-ratio=250 --scene-path=. -Idummy vlc://quit >>$LOGFILE 2>&1
        mv scene00001.png $IFN
    fi
  done <$OUTDIR/chanscan.log
  if [ $P -lt $PMAX ]
  then
    # Pause before next pass
    echo "Sleeping $PAUSE seconds before next pass..."
    sleep $PAUSE
  fi
done

echo "</body>" >> $OUTFILE

# Cleaunup
rm $OUTDIR/out.png 2>/dev/null
rm $OUTDIR/out.mpg 2>/dev/null

exit 0

### These ffmpeg commands are better, but seemed to cause the lines in the
### input file to get corrupted and screw up the loop index, VLC didn't.
### Should figure out why...

#ffmpeg -y -i out.mpg -ss 00:00:00.500 -vframes 1 out.png >> $LOGFILE 2>&1
#ffmpeg -y -i out.mpg -ss 00:00:00.500 -vframes 1 $IFN >> $LOGFILE 2>&1
#`ffmpeg -y -i out.mpg -ss 00:00:00.500 -vframes 1 out.png >> $LOGFILE 2>&1`
#avconv -y -i out.mpg -ss 00:00:00.500 -vframes 1 $IFN
#avconv -i out.mpg -vsync 1 -vframes 1 -an -y $OUTFILE/CAPvideoframe%d.jpg
#mplayer -vo jpeg -sstep 5 -endpos 1 out.mpg

