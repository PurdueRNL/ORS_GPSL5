#!/bin/bash

## Inputs ##
freqIn=1.57542 # GHz
rateIn=10 # MHz
gain=40 # dB
rtime=1 # sec
addr="addr=192.168.10.2" # IP address of N200
dtype="sc8" # Data type
to_collect=3600 # Number of datafiles to collect before reconnecting to N200
nfiles=3600 # Total number of datafiles to collect

sudo sysctl -w net.core.rmem_max=480000000
sudo sysctl -w net.core.wmem_max=480000000

# Set parameters
freq=$(echo "$freqIn*1000000000" | bc) # Convert from GHz to Hz
rate=$(echo "$rateIn*1000000" | bc) # Convert from MHz to Hz
subdev="A:0" # Subdevice specification (parameter for USRP)
nsamp=$(($rate*$rtime)) # Total number of samples to gather

# Initialize loop variables
run=1

# Call binary program to collect data and check data for drops/overflows
while (($run <= ($nfiles / $to_collect))); do
    # Get time for file naming
    tstamp=$(date "+%Y%m%d%H%M%S")

    # Set filenames
    dfile="../../Data/XMTest_${tstamp}.dat" # Datafile
    rfile="../../Data/XMTest_${tstamp}.txt" # Log file

    # Calculate batch number
    let num_batch=$nfiles/$to_collect

    # Report file status
    clear
    echo "Collecting databatch $run/$num_batch"
    echo "Creating files starting at $dfile"

    # Run binary program, passing arguments through command line, to collect data
    ../CppProgram/Other/rx_multi_samplesv3 --args "$addr" --time $rtime --to_collect $to_collect --rate $rate --subdev "$subdev" --freq $freq --file "$dfile" --gain "$gain" --wirefmt "$dtype" --cpufmt "$dtype"

    # Increment loop counter variable
    let run=$run+1
done

# 
echo "$nfiles datafiles were collected."
