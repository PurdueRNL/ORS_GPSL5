#!/bin/bash

## Inputs ##
freqIn=1.57542 # GHz
rateIn=25 # MHz
gain=40 # dB
rtime=1 # Length (in seconds) of one section
addr="addr=192.168.10.2" # IP address of N200
dtype="sc8" # Data type
section_amount=10 # Number of sections in each file
to_collect=6 # Number of files to collect before reconnecting
nfiles=14400 # Total number of datafiles to collect (-1 for infinite)

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
    dfile="../../Data/XMTest_" # Datafile
    rfile="../../Data/XMTest_${tstamp}.txt" # Log file

    # Calculate batch number
    let num_batch=$nfiles/$to_collect

    # Report file status
    clear
    echo "Collecting databatch $run/$num_batch"
    echo "Creating files starting at $dfile"

    # Run binary program, passing arguments through command line, to collect data
    ../CppProgram/Other/rx_multi_samplesv3 --args "$addr" --time $rtime --to_collect $to_collect --section_amount $section_amount --rate $rate --subdev "$subdev" --freq $freq --file "$dfile" --gain "$gain" --wirefmt "$dtype" --cpufmt "$dtype"

    # Increment loop counter variable
    let run=$run+1
done

# 
echo "$nfiles datafiles were collected."
