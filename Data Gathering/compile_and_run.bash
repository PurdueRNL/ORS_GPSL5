#!/bin/bash

# Verify this computer is on the right network
sudo ifconfig eth0 192.168.10.1

# Compile cpp file
cd Code/CppProgram
sudo ./rx_comp.bash

# Begin data collection
cd ../BashScripts
sudo ./run_test_N200.bash
