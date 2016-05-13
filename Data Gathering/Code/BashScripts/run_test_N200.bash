#!/bin/bash

########## INPUTS ##########
freqIn=1.57542 # GHz
rateIn=50 # MHz
gain=40 # dB
rtime=10 # sec
addr="addr=192.168.10.2"
dtype="sc8" # Data type
########## END INPUTS ##########

clear
sudo sysctl -w net.core.rmem_max=480000000
sudo sysctl -w net.core.wmem_max=480000000

## XM Recording Parameters ##
freq=$(echo "$freqIn*1000000000" | bc)
rate=$(echo "$rateIn*1000000" | bc)
#tstamp=$1
subdev="A:0" # set subdev
nsamp=$(($rate*$rtime)) # compute number of samples

let ntime=$rateIn/$rtime

lcv=1

echo "Generating $ntime datafiles..."

while ((lcv <= ntime)); do
    tstamp=$(date "+%Y%m%d%H%M%S")
    ofile1="../../Data/XMTest_${tstamp}.dat" #file name string
    rfile="../../Data/XMTest_${tstamp}.txt" #log file to record number of overflows
    echo "Creating file..."
    echo $ofile1

    for i in `seq 1 3`;
        do
        ../CppProgram/rx_samples_to_file --args "$addr" --time $rtime --nsamp $nsamp --rate $rate --subdev "$subdev" --freq $freq --channels "0" --file1 "$ofile1" --gain $gain  --wirefmt "$dtype" --cpufmt "$dtype"

    done 
    let lcv=lcv+1
done
