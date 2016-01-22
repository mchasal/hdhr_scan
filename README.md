# hdhr_scan
A simple tool to scan channels and generate screenshots on older HDHomeRun cable TV tuners.
Generates a very simple HTML file to view the results.

Prereqs:
    hdhomerun_config
    vlc (currently due to ffmpeg issue)

Once you have the prereqs installed, edit the hdhr_scan.sh script. There are a few
variables at the top to set:

ID=101B8CCA # HDHomeRun device ID
T=tuner1 # Tuner to use (use the least popular one)

PMAX=6 # Number of passes to make, set to one more than you want
PAUSE=600 # sleep time in between passes, longer time will spread 
        # out the screencaps for more variety

OUTDIR=~/hdhr_scan/ # Desired output directory

Then simply run hdhr_scan.sh, it will run for quite a while depending on
your configuration parameters and number of channels. 

After it's complete open the index.html file in the output directory in a 
browser to view the results.


TODO:
    -Take parameters as command line opts
    -Redo this in Python? It got more complicated as it developed.
    -Figure out ffmpeg problem for better frame extraction

