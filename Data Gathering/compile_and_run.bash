#!/bin/bash

# Verify this computer is on the right network
sudo ifconfig eth0 192.168.10.1

# Compile cpp file
cd Code/CppProgram
g++ rx_samples_to_file.cpp -luhd -lpthread -lboost_program_options -lboost_filesystem -lboost_thread -lboost_serialization -lboost_system -o rx_samples_to_file

# Begin data collection
cd ../BashScripts
sudo ./run_test_N200.bash
