#!/bin/bash

g++ rx_samples_to_file_old.cpp -luhd -lpthread -lboost_program_options -lboost_filesystem -lboost_thread -lboost_serialization -lboost_system -o rx_samples_to_file  
