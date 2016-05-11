#!/bin/bash

## INPUTS ##

freqIn=1.57542 # GHz
rateIn=50 # MHz
gain=40 # dB
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

# Number of datafiles to generate
let ntime=$rateIn/$rtime

# Read XM data
echo "Collecting $ntime datafiles..."

lcv=1 # How many datafiles have been read

# Record Data for $rtime seconds
while ((lcv <= ntime)); do
    tstamp=$(date "+%Y%m%d%H%M%S") # Get computer time (for file naming)

    # Assign file names and locations
    ofile="../../Data/XMTest_${tstamp}.dat" # File name of datafile
    rfile="../../Data/XMTest_${tstamp}.txt" # File name of log file

    # Call C++ program that actually collects and writes the data to file
    ../CppProgram/rx_samples_to_file --args "$addr" --time $rtime --nsamp $nsamp --rate $rate --subdev "$subdev" --freq $freq --channels "0" --file "$ofile" --rfile "$rfile" --gain $gain  --wirefmt "$dtype" --cpufmt "$dtype" # Uses double quotes for string variables so the command doesn't split them at commas

    # Check if data has drops or overflows
    read logData < $rfile # If rfile has anything in it, there were drops or overflows

    if [ $logData != 0 ]; then
        rm $ofile # Remove datafile
        echo "Bad data. Removing and retrying ($lcv/$ntime)..."
    else
        echo "Data collected ($lcv/$ntime)"
        let lcv=lcv+1 # increment lcv
    fi
    rm $rfile # Remove log file
done
