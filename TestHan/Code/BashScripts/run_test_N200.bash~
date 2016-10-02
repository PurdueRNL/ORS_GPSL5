#!/bin/bash


## INPUTS ##

freq=1.57542 # GHz
rate=10 # MHz
gain=40
rtime=1800 # Seconds
addr=""
dtype="sc16" # Data type

## END INPUTS ##


clear
sudo sysctl -w net.core.rmem_max=480000000
sudo sysctl -w net.core.wmem_max=480000000
#sudo ifconfig eth0 192.168.10.1

## XM Recording Parameters ##
echo "Setting parameters..."
freq=$(echo "$freq*1000000000" | bc)
rate=$(echo "$rate*1000000" | bc)
gain=$gain
tstamp=$1 # get time stamp from first command line parameter
subdev="A:A A:B" # set subdev
nsamp=$(($rate*$rtime)) # compute number of samples

echo "Frequency: $freq"
echo "Rate: $rate"
echo "Gain: $gain"

#freq=2000000000 # set center frequency
#freq=1575420000 # 2343200000 set center frequency  GPS: 1575420000
#rate=50000000 # set sampling rate
#gain=40 # Set gain
#addr="serial=F5C1CA, master_clock_rate=16e6" #set USRP and master
#addr="addr=192.168.10.2"; clock rate
#tstamp=$1 # get time stamp from first command line parameter
#subdev="A:0" # set subdev
#rtime=10 # recording time in seconds
#rtime=$2 #get time to record from the main program
#nsamp=$(($rate*$rtime)) # compute number of samples
#dtype="sc8" # data type

# Compute number of times to run to make it up to 16 seconds
let ntime=1800/$rtime 


# Read XM data

echo "Writing XM signal to file..."


lcv=1
# Record Data for 16 seconds
while ((lcv <= ntime)); do
tstamp=$(date "+%Y%m%d%H%M%S")
# LHCP
ofile1="/home/rnl_lab/Desktop/TestHan/Data/XMTest_${tstamp}.dat" #file name string
rfile="/home/rnl_lab/Desktop/TestHan/Data/XMTest_${tstamp}.txt" #log file to record number of overflows
echo "Creating file...."
echo $ofile1

for i in `seq 1 3`;
do
/home/rnl_lab/Desktop/TestHan/Code/CppProgram/rx_samples_to_file --args "$addr" --time $rtime --nsamp $nsamp --rate $rate --subdev "$subdev" --freq $freq --channels "0" --file "$ofile1" --gain $gain  --wirefmt "$dtype" --cpufmt "$dtype" # double quotes for string variables so the command doesn't split them at commas

#read nover < $rfile
#echo $nover

#if [ $nover -eq 0 ]
#then
#break
#fi
#echo "Overflow Detected. Retrying..."
#rm $ofile1

done 
let lcv=lcv+1
#echo $lcv
done


