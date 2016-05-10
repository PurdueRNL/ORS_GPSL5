#!/bin/bash

## INPUTS ##

freqIn=1.57542 # GHz
rateIn=50 # MHz
gain=40
rtime=10 # Seconds
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

# Compute number of times to run to make it up to $rtime seconds
let ntime=$rateIn/$rtime

# Read XM data
echo "Writing XM signal to file..."

lcv=1 # Variable to keep track of how many datafiles have been read

# Record Data for $rtime seconds
while ((lcv <= ntime)); do
    tstamp=$(date "+%Y%m%d%H%M%S") # Get computer time (for file naming)

    # LHCP
    ofile1="../../Data/XMTest_${tstamp}.dat" # File name of datafile
    rfile="../../Data/XMTest_${tstamp}.txt" # File name of log file

    # Log the filename of the datafile created
    echo "Creating file...."
    echo $ofile1

    # Call C++ program that actually collects and writes the data to file
    ../CppProgram/rx_samples_to_file --args "$addr" --time $rtime --nsamp $nsamp --rate $rate --subdev "$subdev" --freq $freq --channels "0" --file "$ofile1" --rfile "$rfile" --gain $gain  --wirefmt "$dtype" --cpufmt "$dtype"
    # Using double quotes for string variables so the command doesn't split them at commas
    let lcv=lcv+1 # Increment lcv
done