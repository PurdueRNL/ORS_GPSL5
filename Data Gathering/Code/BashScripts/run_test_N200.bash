#!/bin/bash

# Inputs
freqIn=1.57542 # GHz
rateIn=50 # MHz
gain=40 # dB
rtime=10 # sec
addr="addr=192.168.10.2" # IP address of N200
dtype="sc8" # Data type


sudo sysctl -w net.core.rmem_max=480000000
sudo sysctl -w net.core.wmem_max=480000000

## XM Recording Parameters ##
freq=$(echo "$freqIn*1000000000" | bc)
rate=$(echo "$rateIn*1000000" | bc)
subdev="A:0" # set subdev
nsamp=$(($rate*$rtime)) # compute number of samples

let ntime=$rateIn/$rtime

run=1   

while ((run <= ntime)); do
    echo "Generating datafile $run/$ntime"

    # Get time for file naming
    tstamp=$(date "+%Y%m%d%H%M%S")

    # Set filenames
    dfile="../../Data/XMTest_${tstamp}.dat" # Datafile
    rfile="../../Data/XMTest_${tstamp}.txt" # Log file

    echo "Creating file $dfile"

    # Run C++ program, passing arguments through command line, to collect data
    ../CppProgram/rx_samples_to_file --args "$addr" --time $rtime --nsamp $nsamp --rate $rate --subdev "$subdev" --freq $freq --channels "0" --rfile "$rfile" --file1 "$dfile" --gain $gain  --wirefmt "$dtype" --cpufmt "$dtype"

    # Check for drops or overflows
    # Grab value of drops+overflows from C++ program
    log=$(<$rfile)
    
    # If there were no drops/overflows, save the datafile and continue - if there were, delete the datafile and retry
    if (($log==0)); then
        rm $rfile
        let run=$run+1
    else
        rm $rfile
        rm $dfile
        echo "Bad data. Retrying..."
    fi
done
