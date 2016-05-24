#!/bin/bash

## Inputs ##
freqIn=1.57542 # GHz
rateIn=50 # MHz
gain=40 # dB
rtime=1 # sec
addr="addr=192.168.10.2" # IP address of N200
dtype="sc8" # Data type
nfiles=3600 # Number of datafiles to collect

sudo sysctl -w net.core.rmem_max=480000000
sudo sysctl -w net.core.wmem_max=480000000

# Set parameters
freq=$(echo "$freqIn*1000000000" | bc) # Convert from GHz to Hz
rate=$(echo "$rateIn*1000000" | bc) # Convert from MHz to Hz
subdev="A:0" # Subdevice specification (parameter for USRP)
nsamp=$(($rate*$rtime)) # Total number of samples to gather

# Initialize loop variables
run=1
attempt=1

# Call binary program to collect data and check data for drops/overflows
while ((run <= nfiles)); do
    # Get time for file naming
    tstamp=$(date "+%Y%m%d%H%M%S")

    # Set filenames
    dfile="../../Data/XMTest_${tstamp}.dat" # Datafile
    rfile="../../Data/XMTest_${tstamp}.txt" # Log file

    clear
    echo "Collecting datafile $run/$nfiles, attempt $attempt"
    echo "Creating file $dfile"

    # Run binary program, passing arguments through command line, to collect data
    ../CppProgram/rx_samples_to_file --args "$addr" --time $rtime --total_runs $nfiles --nsamp $nsamp --rate $rate --subdev "$subdev" --freq $freq --channels "0" --rfile "$rfile" --dfile "$dfile" --gain "$gain" --wirefmt "$dtype" --cpufmt "$dtype"
    let run=$run+1
done # While loop instead of for loop because sometimes bad data should stop the counter variable from incrementing

echo "$nfiles datafiles were collected."
