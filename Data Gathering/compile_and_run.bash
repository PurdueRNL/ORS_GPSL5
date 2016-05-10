#!/bin/bash

# Compile cpp file
cd Code/CppProgram
sudo ./rx_comp.bash

# Begin data collection
cd ../BashScripts
sudo ./run_test_N200.bash
