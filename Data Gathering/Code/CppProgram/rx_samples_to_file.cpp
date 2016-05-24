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

#include <uhd/types/tune_request.hpp>
#include <uhd/utils/thread_priority.hpp>
#include <uhd/convert.hpp>
#include <uhd/utils/safe_main.hpp>
#include <uhd/usrp/multi_usrp.hpp>
#include <uhd/exception.hpp>
#include <boost/program_options.hpp>
#include <boost/format.hpp>
#include <boost/thread.hpp>
#include <boost/lexical_cast.hpp>
#include <boost/algorithm/string.hpp>
#include <boost/date_time/posix_time/posix_time.hpp>
#include <iostream>
#include <fstream>
#include <csignal>
#include <complex>

namespace po = boost::program_options;

static bool stop_signal_called = false;
void sig_int_handler(int){stop_signal_called = true;}

double elapsed_time(const boost::system_time t2, const boost::system_time t1)
{
    return double((t2-t1).ticks()) / boost::posix_time::time_duration::ticks_per_second();
}

/***********************************************************************
 * Test result variables
 **********************************************************************/
unsigned long long num_overflows = 0;
unsigned long long num_rx_samps = 0;
unsigned long long num_dropped_samps = 0;
unsigned long long last_overflow_num_samps = 0;

/***********************************************************************
 * Benchmark RX Rate
 **********************************************************************/
// This function actually collects the XM data
void benchmark_rx_rate(
    uhd::usrp::multi_usrp::sptr usrp,
    const std::string &rx_cpu,
    uhd::rx_streamer::sptr rx_stream,
    const std::string &dfile,
    size_t num_of_samps){

    uhd::set_thread_priority_safe();

    //setup variables and allocate buffer
    uhd::rx_metadata_t md;

    const size_t samps_per_buff = rx_stream->get_max_num_samps();
    const size_t num_chan = rx_stream->get_num_channels();
    const size_t bytes_per_samp = uhd::convert::get_bytes_per_item(rx_cpu);

    //allocate buffers to receive with samples (one buffer per channel)
    std::vector<std::vector<char> > buffs(num_chan, std::vector<char>(samps_per_buff*bytes_per_samp));

    //create a vector of pointers to point to each of the channel buffers
    std::vector<char*> buff_ptrs;
    for (size_t i = 0; i < num_chan; i++) buff_ptrs.push_back(&buffs[i].front());

    // create a separate output file for each channel
    std::ofstream outfile[num_chan];
    outfile[0].open((boost::format("%s") % dfile ).str().c_str(), std::ofstream::binary);

    bool had_an_overflow = false;
    uhd::time_spec_t last_time;
    const double rate = usrp->get_rx_rate();

    uhd::stream_cmd_t cmd(uhd::stream_cmd_t::STREAM_MODE_START_CONTINUOUS);

    const double start_delay = 0.05;
    double timeout = start_delay + 0.1;
    cmd.time_spec = usrp->get_time_now() + uhd::time_spec_t(start_delay);
    cmd.stream_now = (buff_ptrs.size() == 1);
    rx_stream->issue_stream_cmd(cmd);
    unsigned long long acc_samps = 0;

    while(acc_samps < num_of_samps && num_dropped_samps == 0){
        unsigned long long tmp_num_samps = 0;

        try {
          tmp_num_samps = rx_stream->recv(buff_ptrs, samps_per_buff, md, timeout);
          num_rx_samps += (tmp_num_samps * num_chan);
          acc_samps += tmp_num_samps;
          timeout = 0.1;
        }
        catch (...) {
          /* apparently, the boost thread interruption can sometimes result in
             throwing exceptions not of type boost::exception, this catch allows
             this thread to still attempt to issue the STREAM_MODE_STOP_CONTINUOUS
          */
          break;
        }

        //handle the error codes
        switch(md.error_code){
        case uhd::rx_metadata_t::ERROR_CODE_NONE:
            if (had_an_overflow){
                had_an_overflow = false;
                num_dropped_samps += (md.time_spec - last_time).to_ticks(rate);
            }
            break;

        // ERROR_CODE_OVERFLOW can indicate overflow or sequence error
        case uhd::rx_metadata_t::ERROR_CODE_OVERFLOW:
            last_time = md.time_spec;
            last_overflow_num_samps = num_rx_samps;
            had_an_overflow = true;
            // check out_of_sequence flag to see if it was a sequence error or overflow
            if (!md.out_of_sequence)
                num_overflows++;
            break;

        default:
            std::cerr << "Receiver error: " << md.strerror() << std::endl;
            std::cerr << "Unexpected error on recv, continuing..." << std::endl;
            break;
        }

        // write the data to the output files
        for (size_t i=0; i<num_chan; i++)
            if (outfile[i].is_open())
                 outfile[i].write((const char*)buff_ptrs[i], tmp_num_samps*bytes_per_samp);
    }
    rx_stream->issue_stream_cmd(uhd::stream_cmd_t::STREAM_MODE_STOP_CONTINUOUS);

    // close the output files
    for (size_t i=0; i<num_chan; i++)
        if (outfile[i].is_open()) outfile[i].close();
}

typedef boost::function<uhd::sensor_value_t (const std::string&)> get_sensor_fn_t;

bool check_locked_sensor(std::vector<std::string> sensor_names, const char* sensor_name, get_sensor_fn_t get_sensor_fn, double setup_time){
	if (std::find(sensor_names.begin(), sensor_names.end(), sensor_name) == sensor_names.end())
		return false;

	boost::system_time start = boost::get_system_time();
	boost::system_time first_lock_time;

	std::cout << boost::format("Waiting for \"%s\": ") % sensor_name;
	std::cout.flush();

	while (true){
		if ((not first_lock_time.is_not_a_date_time()) and
			(boost::get_system_time() > (first_lock_time + boost::posix_time::seconds(setup_time))))
		{
			std::cout << " locked." << std::endl;
			break;
		}

		if (get_sensor_fn(sensor_name).to_bool()){
			if (first_lock_time.is_not_a_date_time())
				first_lock_time = boost::get_system_time();
			std::cout << "+";
			std::cout.flush();
		}
		else{
			first_lock_time = boost::system_time();	//reset to 'not a date time'

			if (boost::get_system_time() > (start + boost::posix_time::seconds(setup_time))){
				std::cout << std::endl;
				throw std::runtime_error(str(boost::format("timed out waiting for consecutive locks on sensor \"%s\"") % sensor_name));
			}

			std::cout << "_";
			std::cout.flush();
		}

		boost::this_thread::sleep(boost::posix_time::milliseconds(100));
	}

	std::cout << std::endl;

	return true;
}

// This function is the main function
int UHD_SAFE_MAIN(int argc, char *argv[]){
    // Declare variables
    po::variables_map vm;
    std::string args, dfile, rfile, ant, subdev, ref, wirefmt, cpufmt, channel_list;
    std::vector<std::string> channel_strings;
    std::vector<size_t> channel_nums;
    std::time_t ltime;
    boost::thread_group thread_group;
    size_t total_num_samps, ch, chan, i;
    double rate, freq, gain, bw, total_time, setup_time, runs_this, wire_rate, cpu_rate, etime1, etime2, sleep_time;
    bool bw_summary;
    int nrun;

    uhd::set_thread_priority_safe();

    //setup the program options
    po::options_description desc("Allowed options");
    desc.add_options()
        ("help", "help message")
        ("args", po::value<std::string>(&args)->default_value(""), "multi uhd device address args")
        ("dfile", po::value<std::string>(&dfile)->default_value("usrp_samples_A.dat"), "name of the file 1 to write binary samples to")
        ("rfile", po::value<std::string>(&rfile)->default_value("usrp_log.txt"), "name of the file to write overflow info to")
        ("runs_this", po::value<double>(&runs_this)->default_value(1), "how many times the program should run")
        ("nsamps", po::value<size_t>(&total_num_samps)->default_value(0), "total number of samples to receive")
        ("time", po::value<double>(&total_time)->default_value(0), "total number of seconds to receive")
        ("rate", po::value<double>(&rate)->default_value(1e6), "rate of incoming samples")
        ("freq", po::value<double>(&freq)->default_value(0.0), "RF center frequency in Hz")
        ("gain", po::value<double>(&gain), "gain for the RF chain")
        ("ant", po::value<std::string>(&ant), "daughterboard antenna selection")
        ("subdev", po::value<std::string>(&subdev), "daughterboard subdevice specification")
        ("channels", po::value<std::string>(&channel_list)->default_value("0"), "which channel(s) to use (specify \"0\", \"1\", \"0,1\", etc)")
        ("bw", po::value<double>(&bw), "daughterboard IF filter bandwidth in Hz")
        ("ref", po::value<std::string>(&ref)->default_value("gpsdo"), "waveform type (internal, external, mimo)")
        ("wirefmt", po::value<std::string>(&wirefmt)->default_value("sc16"), "wire format (sc8 or sc16)")
        ("cpufmt", po::value<std::string>(&cpufmt)->default_value("sc16"), "cpu format (sc8, sc16, fc32, or fc64)")
        ("setup", po::value<double>(&setup_time)->default_value(1.0), "seconds of setup time")
        ("progress", "periodically display short-term stats")
        ("skip-lo", "skip checking LO lock status")
        ("int-n", "tune USRP with integer-N tuning")
    ;
    po::store(po::parse_command_line(argc, argv, desc), vm);
    po::notify(vm);

    //print the help message
    if (vm.count("help")){
        std::cout << boost::format("UHD RX samples to file %s") % desc << std::endl;
        return ~0;
    }

    bw_summary = vm.count("progress") > 0;

    //create a usrp device
    std::cout << std::endl;
    uhd::usrp::multi_usrp::sptr usrp = uhd::usrp::multi_usrp::make(args);

    //Lock mboard clocks
    usrp->set_clock_source(ref);
    //\\//\\//\\//\\//\\ HERE IS WHERE CLOCK SETTING STUFF GOES //\\//\\//\\//\\//\\

    //always select the subdevice first, the channel mapping affects the other settings
    if (vm.count("subdev")) usrp->set_rx_subdev_spec(subdev);

    //set the sample rate
    if (rate <= 0.0){
        std::cerr << "Please specify a valid sample rate" << std::endl;
        return ~0;
    }

    usrp->set_rx_rate(rate);

    //detect which channels to use
    boost::split(channel_strings, channel_list, boost::is_any_of("\"',"));
    for(ch = 0; ch < channel_strings.size(); ch++){
        chan = boost::lexical_cast<int>(channel_strings[ch]);
        if(chan >= usrp->get_rx_num_channels()){
            throw std::runtime_error("Invalid channel(s) specified.");
        }
        else channel_nums.push_back(boost::lexical_cast<int>(channel_strings[ch]));
    }

    //set the center frequency
    if (vm.count("freq")){	//with default of 0.0 this will always be true
        uhd::tune_request_t tune_request(freq);
        if(vm.count("int-n")) tune_request.args = uhd::device_addr_t("mode_n=integer");
        for(i=0; i<channel_nums.size(); i++) {
            usrp->set_rx_freq(tune_request, channel_nums[i]);
        }
        std::cout << std::endl;
	}

    //set the rf gain
    if (vm.count("gain")){
        for(i=0; i<channel_nums.size(); i++) {
            usrp->set_rx_gain(gain, channel_nums[i]);
        }
        std::cout << std::endl;
    }

    //set the IF filter bandwidth
    if (vm.count("bw")){
        for(i=0; i<channel_nums.size(); i++) {
            usrp->set_rx_bandwidth(bw, channel_nums[i]);
        }
        std::cout << std::endl;
    }

    //set the antenna
    if (vm.count("ant")){
        for(i=0; i<channel_nums.size(); i++){
            usrp->set_rx_antenna(ant, channel_nums[i]);
        }
    }

    boost::this_thread::sleep(boost::posix_time::seconds(setup_time)); //allow for some setup time

    //check Ref and LO Lock detect
    if (not vm.count("skip-lo")){
		check_locked_sensor(usrp->get_rx_sensor_names(0), "lo_locked", boost::bind(&uhd::usrp::multi_usrp::get_rx_sensor, usrp, _1, 0), setup_time);
		if (ref == "mimo")
			check_locked_sensor(usrp->get_mboard_sensor_names(0), "mimo_locked", boost::bind(&uhd::usrp::multi_usrp::get_mboard_sensor, usrp, _1, 0), setup_time);
		if (ref == "external")
			check_locked_sensor(usrp->get_mboard_sensor_names(0), "ref_locked", boost::bind(&uhd::usrp::multi_usrp::get_mboard_sensor, usrp, _1, 0), setup_time);
	}

    //create a receive streamer
    uhd::stream_args_t stream_args(cpufmt,wirefmt);
    stream_args.channels = channel_nums;
    uhd::rx_streamer::sptr rx_stream = usrp->get_rx_stream(stream_args);

    //print pre-test info
    wire_rate = usrp->get_rx_rate()*rx_stream->get_num_channels()*uhd::convert::get_bytes_per_item(wirefmt);
    cpu_rate = usrp->get_rx_rate()*rx_stream->get_num_channels()*uhd::convert::get_bytes_per_item(cpufmt);

    // Setup Ctrl-C interrupt handler 
    std::signal(SIGINT, &sig_int_handler);
    std::cout << "Press Ctrl + Z to abort..." << std::endl << std::endl;

    nrun = 1;

    while (nrun <= runs_this) {
        time(&ltime);
        dfile = "../../Data/XMTest_" + boost::to_string(ltime) + ".dat";  

        //spawn the receive test thread
        thread_group.create_thread(boost::bind(&benchmark_rx_rate, usrp, cpufmt, rx_stream, dfile, total_num_samps));

        //Wait for the desired time interval and then stop the receive test thread
        //Also, monitor the progress along the way
        sleep_time = total_time + 0.1;
        boost::system_time start = boost::get_system_time();
        boost::system_time previous = start;

        while (not stop_signal_called) {
            boost::this_thread::sleep(boost::posix_time::milliseconds(100));
            boost::system_time now = boost::get_system_time();

            etime1 = elapsed_time(now,start);
            if (etime1 > sleep_time) break;

            if (num_dropped_samps != 0) break;


            if (bw_summary) {
                etime2 = elapsed_time(now,previous);
                if (etime2 > 1.0) {
                    std::cout << boost::format("Time elapsed (s): %0.1f; Received samps (MSa): %0.1f") % etime1 % (double(num_rx_samps)/1e6) << std::endl;
                    previous = now;
                }
            }
        }
        nrun++;

        // Interrupt and join the threads
        thread_group.interrupt_all();
        thread_group.join_all();

        // Remove datafile if there were drops or overflows and alert user of progress
        if ((num_overflows + num_dropped_samps) > 0) {
            std::remove(dfile.c_str());
            std::cout << "-";
            std::cout.flush();
        }
        else {
            std::cout << "+";
            std::cout.flush();
        }
        std::cout << num_dropped_samps;
        std::cout.flush();
    }

    return EXIT_SUCCESS;
}
