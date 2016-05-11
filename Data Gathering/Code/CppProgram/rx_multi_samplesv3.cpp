//
// Copyright 2010-2011,2014 Ettus Research LLC
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
// Modified by Zenki @ Purdue
// Furthur modified by hheim @ Purdue

#include <uhd/types/tune_request.hpp>
#include <uhd/utils/thread_priority.hpp>
#include <uhd/utils/safe_main.hpp>
#include <uhd/usrp/multi_usrp.hpp>
#include <uhd/exception.hpp>
#include <boost/program_options.hpp>
#include <boost/format.hpp>
#include <boost/thread.hpp>
#include <iostream>
#include <fstream>
#include <csignal>
#include <complex>

// =====================================
#include <uhd/convert.hpp>
#include <boost/lexical_cast.hpp>
#include <boost/algorithm/string.hpp>
#include <uhd/utils/paths.hpp>
#include <uhd/transport/usb_control.hpp>
#include <uhd/transport/usb_device_handle.hpp>
#include <uhd/config.hpp>
#include <boost/functional/hash.hpp>
// =====================================


namespace po = boost::program_options;


int UHD_SAFE_MAIN(int argc, char *argv[]){
    uhd::set_thread_priority_safe();

    //variables to be set by po
    std::string args, file, type, ant, subdev, ref, wirefmt, cpufmt;
    size_t total_num_samps, spb;
    double rate, freq, gain, bw, total_time, setup_time;
	
    //setup the program options
    po::options_description desc("Allowed options");
    desc.add_options()
        ("help", "help message")
        ("args", po::value<std::string>(&args)->default_value(""), "multi uhd device address args")
        ("file", po::value<std::string>(&file)->default_value("usrp_samples.dat"), "name of the file to write binary samples to")
        ("type", po::value<std::string>(&type)->default_value("short"), "sample type: double, float, or short")
        ("time", po::value<double>(&total_time), "(DEPRECATED) will go away soon! Use --duration instead")
        ("spb", po::value<size_t>(&spb)->default_value(10000), "samples per buffer")
        ("rate", po::value<double>(&rate)->default_value(1e6), "rate of incoming samples")
        ("freq", po::value<double>(&freq)->default_value(0.0), "RF center frequency in Hz")
        ("gain", po::value<double>(&gain)->default_value(0.0), "gain for the RF chain")
		("subdev", po::value<std::string>(&subdev), "daughterboard subdevice specification")
        ("bw", po::value<double>(&bw)->default_value(0.0), "analog frontend filter bandwidth in Hz")
        ("ref", po::value<std::string>(&ref)->default_value("internal"), "reference source (internal, external, mimo)")
        ("wirefmt", po::value<std::string>(&wirefmt)->default_value("sc16"), "wire format (sc8 or sc16)")
		("cpufmt", po::value<std::string>(&cpufmt)->default_value("sc16"), "cpu format (sc8, sc16, fc32, or fc64)")
        ("setup", po::value<double>(&setup_time)->default_value(1.0), "seconds of setup time")		
        ("progress", "periodically display short-term bandwidth")
        ("stats", "show average bandwidth on exit")
        ("sizemap", "track packet size and display breakdown on exit")
        ("null", "run without writing to file")
        ("continue", "don't abort on a bad packet")
        ("skip-lo", "skip checking LO lock status")
        ("int-n", "tune USRP with integer-N tuning")
    ;
    po::variables_map vm;
    po::store(po::parse_command_line(argc, argv, desc), vm);
    po::notify(vm);

    //print the help message
    if (vm.count("help")) {
        std::cout << boost::format("UHD RX samples to file %s") % desc << std::endl;
        std::cout
            << std::endl
            << "This application streams data from a single channel of a USRP device to a file.\n"
            << std::endl;
        return ~0;
    }

    bool bw_summary = vm.count("progress") > 0;
    bool stats = vm.count("stats") > 0;
    bool null = vm.count("null") > 0;
    bool enable_size_map = vm.count("sizemap") > 0;
    bool continue_on_bad_packet = vm.count("continue") > 0;

    if (enable_size_map)
        std::cout << "Packet size tracking enabled - will only recv one packet at a time!" << std::endl;

    //create a usrp device
    std::cout << std::endl;
    std::cout << boost::format("Creating the usrp device with: %s...") % args << std::endl;
    uhd::usrp::multi_usrp::sptr usrp = uhd::usrp::multi_usrp::make(args);

	// ==========================
	//set the center frequency
	uhd::tune_request_t tune_request(freq);
	usrp->set_rx_freq(tune_request, 0);

	
	//set the rf gain
	usrp->set_rx_gain(gain, 0);
	
	//set the IF filter bandwidth
    usrp->set_rx_bandwidth(bw, 0);
	
    // *********************** This would be used once the N200 has a GPSDO installed ************************* \\
    //Lock mboard clocks
    /*usrp->set_clock_source(ref);
	usrp->set_clock_source("gpsdo",0);
    usrp->set_time_source("gpsdo",0);*/

    // TEMPORARY
    usrp->set_clock_source("external");
    // /TEMPORARY
	
	//set subdev
	usrp->set_rx_subdev_spec(subdev);   

    //set the sample rate
	usrp->set_rx_rate(rate);
	
	//set rxstream
	std::vector<size_t> channel_nums;
	channel_nums.push_back(0);
	
	uhd::stream_args_t stream_args(cpufmt,wirefmt);
    stream_args.channels = channel_nums;
    uhd::rx_streamer::sptr rx_stream = usrp->get_rx_stream(stream_args);
	const size_t samps_per_buff = rate;
	const size_t samps_per_temp = rate; 	
	//print pre-test info
    double wire_rate = usrp->get_rx_rate()*rx_stream->get_num_channels()*uhd::convert::get_bytes_per_item(wirefmt);
    double cpu_rate = usrp->get_rx_rate()*rx_stream->get_num_channels()*uhd::convert::get_bytes_per_item(cpufmt);
 	
	// create buffer
	const size_t bytes_per_samp = uhd::convert::get_bytes_per_item(cpufmt);
    //                                                                                     Affects number of files per run
	std::vector<std::vector<char> > buffs(rx_stream->get_num_channels(), std::vector<char>(samps_per_buff*bytes_per_samp));
    std::vector<char*> buff_ptrs;
	buff_ptrs.push_back(&buffs[0].front());
	
	uhd::rx_metadata_t md;
	uhd::stream_cmd_t cmd(uhd::stream_cmd_t::STREAM_MODE_START_CONTINUOUS);
	
	// set time stream
    const double start_delay = 0.05;
    double timeout = start_delay + 0.1;
    cmd.time_spec = usrp->get_time_now() + uhd::time_spec_t(start_delay);
    cmd.stream_now = (buff_ptrs.size() == 1);
    rx_stream->issue_stream_cmd(cmd);

	// create files
	std::ofstream outfile[2];
	const char header[]={'P','U','R','D','U','E'};
	const char subheader[]={'A','A','E','A','A','E'};	
	const char subend[]={'X','X'};	
	
	// start recording
	bool had_an_overflow = false;
    uhd::time_spec_t last_time;
	unsigned long long num_overflows = 0;
	unsigned long long num_normal = 0;
	unsigned long long num_dropped_samps = 0;
	unsigned long long last_overflow_num_samps = 0;	
	size_t acc_rx_samps = 0;	
	
	time_t rawtime;
	struct tm * timeinfo;
	char time_str [18];
	
	//spawn the receive test thread
    boost::thread_group thread_group;
	std::cout << boost::format("Time: %d") % (thread_group.size()) << std::endl;   
	
	
	// Display settings
    std::cout << std::endl;
	std::cout << boost::format("File     	%s") % file << std::endl;	
	std::cout << boost::format("Time     	%0.1f	Sec") % total_time << std::endl;
	std::cout << boost::format("Channel		%d/%d	%d") % (usrp->get_rx_num_channels()) % (channel_nums[0]) % (channel_nums[1])<< std::endl;
	std::cout << boost::format("Buff		%d") % (rx_stream->get_max_num_samps()) << std::endl;
	std::cout << boost::format("Wire/CPU	%d/%d	Bytes") % (uhd::convert::get_bytes_per_item(wirefmt)) % (uhd::convert::get_bytes_per_item(cpufmt)) << std::endl;	
	std::cout << boost::format("Cpu rate	%0.1f	MB/sec")  % (cpu_rate/1e6) << std::endl;	
	std::cout << boost::format("Rate     	%0.1f	MHz") % (usrp->get_rx_rate()/1e6) << std::endl;	
	std::cout << boost::format("Gain     	%0.1f	dB") % usrp->get_rx_gain(0)<< std::endl;
	std::cout << boost::format("Frequency	%0.1f	MHz") % (usrp->get_rx_freq(0)/1e6) << std::endl;
	std::cout << boost::format("Bandwidth	%0.1f	MHz") % (usrp->get_rx_bandwidth(0)/1e6) << std::endl << std::endl;

	size_t f = 0;
	while (f < (total_time*10)) {
		
		if ((acc_rx_samps>rate) || (f==0)){
			
			if (outfile[0].is_open()) outfile[0].close();
						
			time(&rawtime);
			timeinfo = localtime (&rawtime);
			strftime(time_str,18,"%Y%m%dT%H%M%SZ",timeinfo);
	 
			outfile[0].open((boost::format("%s") % file).str().c_str(), std::ofstream::binary);
			std::cout << boost::format("Time:%d %s :: %d/%d %d/%d") % f % time_str % acc_rx_samps %rate % num_overflows % num_normal << std::endl;   
			
            // overflow checking
			if (num_overflows>3) {
				cmd.stream_mode = uhd::stream_cmd_t::STREAM_MODE_STOP_CONTINUOUS;
				rx_stream->issue_stream_cmd(cmd);
				
				boost::this_thread::sleep(boost::posix_time::milliseconds(100));
				cmd.stream_mode = uhd::stream_cmd_t::STREAM_MODE_START_CONTINUOUS;
				cmd.time_spec = usrp->get_time_now() + uhd::time_spec_t(start_delay);
				cmd.stream_now = (buff_ptrs.size() == 1);
				rx_stream->issue_stream_cmd(cmd);
			}
			
			acc_rx_samps = 0;
			num_overflows = 0;
			num_normal = 0;

            std::cout.flush();			
			for (size_t i = 0; i < 1; i++) {
					double sig_env[] = {cpu_rate,
										usrp->get_rx_rate(),
										channel_nums[i],
										usrp->get_rx_gain(i),
										usrp->get_rx_freq(i),
										usrp->get_rx_bandwidth(i)
					};
				
					outfile[i].write((const char*)header, sizeof(header));
					outfile[i].write((const char*)sig_env, sizeof(sig_env));
					outfile[i].write((const char*)subend, sizeof(subend));		
			}
			
			f++;
		}	

		size_t num_rx_samps = rx_stream->recv(buff_ptrs, samps_per_buff, md, timeout);
		last_time = md.time_spec;
		
		acc_rx_samps += num_rx_samps;
		
		for (size_t i = 0; i < 1; i++) {

			outfile[i].write((const char*)subheader, sizeof(subheader));
			outfile[i].write((const char*)&num_rx_samps, sizeof(num_rx_samps));
			outfile[i].write((const char*)subend, sizeof(subend));	
			outfile[i].write((const char*)buff_ptrs[i], num_rx_samps*bytes_per_samp);	
			outfile[i].flush();			
		}

		switch(md.error_code){
			case uhd::rx_metadata_t::ERROR_CODE_NONE:
				num_normal++;
				break;

			case uhd::rx_metadata_t::ERROR_CODE_OVERFLOW:
				num_overflows++;
				break;
		}
		
	}
	
	if (outfile[0].is_open()) outfile[0].close();
	
	boost::this_thread::sleep(boost::posix_time::seconds(setup_time)); //allow for some setup time
    return EXIT_SUCCESS;
}
