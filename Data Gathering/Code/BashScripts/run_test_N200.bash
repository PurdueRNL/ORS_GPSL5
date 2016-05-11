#!/bin/bash

## INPUTS ##

freqIn=1.57542 # GHz
rateIn=50 # MHz
gain=40 # dB
rtime=10 # sec
addr="addr=192.168.10.2" # Local IP address of the N200
dtype="sc8" # Data type

## END INPUTS ##

# Allocate memory for storing the large datafiles
sudo sysctl -w net.core.rmem_max=480000000
sudo sysctl -w net.core.wmem_max=480000000

## XM Recording Parameters ##
freq=$(echo "$freqIn*1000000000" | bc) # Convert frequency from GHz to Hz
rate=$(echo "$rateIn*1000000" | bc) # Convert rate from MHz to Hz
subdev="A:0" # Set subdev
nsamp=$(($rate*$rtime)) # Compute number of samples in each datafile

# Print values to screen (for debugging)
echo "Setting parameters..."
echo "Frequency: $freq"
echo "Rate: $rate"
echo "Gain: $gain"

# Number of datafiles to generate
let ntime=$rateIn/$rtime

# Read XM data
echo "Collecting $ntime datafiles..."

lcv=1 # How many datafiles have been read

# Record Data for $rtime seconds
while ((lcv <= ntime)); do
    # Get computer time (for file naming)
    tstamp=$(date "+%Y%m%d%H%M%S")

    # Assign file names and locations
    ofile="../../Data/XMTest_${tstamp}.dat" # File name of datafile

    # Call C++ program that actually collects and writes the data to file
    ../CppProgram/rx_multi_samplesv3 --args "$addr" --time $rtime --rate $rate --subdev "$subdev" --freq $freq --file "$ofile" --gain $gain  --wirefmt "$dtype" --cpufmt "$dtype"

    let lcv=$lcv+1
done
