#!/usr/bin/python
import serial
import sys
import datetime
import time
import atexit
import struct
import matplotlib.pyplot as plt
import numpy.fft as fft
import numpy

print '========================================'
print '  SoOp RT - input buffer data analyzer  '
print '========================================'
print '1) Description: receives input buffer data from the FPGA and shows relevant plots'
print '2) Input data: 4096 samples of direct I/Q and reflected I/Q, 8-bit each'
print '3) Output:'
print '  Figure 1 - direct I/Q and reflected I/Q shown in graphs'
print '  Figure 2 - power spectrum of the direct signal'
print '  Figure 3 - power spectrum of the reflected signal'
print '  Figure 4 - correlation result of the dir/ref signals'
print ' '


filename_str = str(sys.argv[1])
print 'reading data from <' + filename_str + '>...'
with open(filename_str, "rb") as data_file:
  file_contents = data_file.read()
file_len = len(file_contents)
if file_len%(4096*4) != 0:
  print 'invalid file length! (' + str(file_len) + ')'
  sys.exit(1)
else:
  num_of_seq = file_len / (4096*4)
  print 'plotting the first sequence out of ' + str(num_of_seq) + ' sequences contained in the file...'

print 'organizing input data......'
# "in_data_int8" type: 8-bit signed integers
in_data_int8 = struct.unpack("<16384b", file_contents[0:4096*4])

# input data comes in [dir_I(0), dir_Q(0), ref_I(0), ref_Q(0), dir_I(1), ...] format
# divide the whole data into individual signals
in_data_dir_i = []
in_data_dir_q = []
in_data_ref_i = []
in_data_ref_q = []
index = 0
for val in in_data_int8:
  mod = index % 4
  if mod == 0: #orginaly 0
    in_data_dir_i.append(val)
  elif mod == 1: #orginaly 1
    in_data_dir_q.append(val)
  elif mod == 2: #orginaly 2
    in_data_ref_i.append(val)
  elif mod == 3: #orginaly 3 
    in_data_ref_q.append(val)
  index = index + 1



print 'creating output figures......'

plt.figure(1)
plt.title('I/Q Element Values')
plt.subplot(411)
plt.title('Direct I')
plt.plot(in_data_dir_i)
plt.subplot(412)
plt.title('Direct Q')
plt.plot(in_data_dir_q)
plt.subplot(413)
plt.title('Reflected I')
plt.plot(in_data_ref_i)
plt.subplot(414)
plt.title('Reflected Q')
plt.plot(in_data_ref_q)
plt.tight_layout()


dir_complex = [a + 1j*b for a,b in zip(in_data_dir_i, in_data_dir_q)]
ref_complex = [a + 1j*b for a,b in zip(in_data_ref_i, in_data_ref_q)]

dir_fft = fft.fft(dir_complex)
ref_fft = fft.fft(ref_complex)
fft_len = len(dir_fft)

# LPF length is based on the bandwidth of the input signal.
# assume that the center frequency is placed exactly on the center of XM3 band
# assume that the input bandwidth is 8 MHz
# then we have to pass only the center 2 MHz (1.4 MHz in exact) to isolate XM3 band
# the center 2 MHz account for 1/4 of the total 8 MHz: thus 1024 out of 4096 indexes
lpf_len = 512
dir_filtered = list(dir_fft[0:lpf_len]) + [0]*(fft_len-lpf_len*2) + list(dir_fft[fft_len-lpf_len:fft_len])
ref_filtered = list(dir_fft[0:lpf_len]) + [0]*(fft_len-lpf_len*2) + list(dir_fft[fft_len-lpf_len:fft_len])

dir_power_spectrum = numpy.abs(dir_fft)**2
# re-arrange the array so that freq 0 is placed at the center
dir_power_spectrum_shifted = fft.fftshift(dir_power_spectrum)
ref_power_spectrum = numpy.abs(ref_fft)**2
# re-arrange the array so that freq 0 is placed at the center
ref_power_spectrum_shifted = fft.fftshift(ref_power_spectrum)

# modify bw_in_mhz when the sample rate changes
bw_in_mhz = 8.0
bw_in_khz = bw_in_mhz * 1000
bw_in_hz = bw_in_khz * 1000
fft_x_axis_step = bw_in_khz / fft_len
fft_x_axis_label = -1 * (bw_in_khz/2)
reference_array = [0]*(fft_len)
x_axis_for_fft = []
for val in reference_array:
  x_axis_for_fft.append(fft_x_axis_label)
  fft_x_axis_label = fft_x_axis_label + fft_x_axis_step

plt.figure(2)
plt.title('Direct Signal - Power Spectrum')
plt.plot(x_axis_for_fft, dir_power_spectrum_shifted)
plt.tight_layout()

plt.figure(3)
plt.title('Reflected Signal - Power Spectrum')
plt.plot(x_axis_for_fft, ref_power_spectrum_shifted)
plt.tight_layout()


conj_mult  = [a * b.conjugate() for a,b in zip(dir_fft, ref_fft)]

corr_raw = fft.ifft(conj_mult)
corr_mag = numpy.abs(corr_raw)
corr_len = len(corr_mag)
corr_mag_shifted = fft.fftshift(corr_mag)
corr_mag_shifted_positive = corr_mag[0:corr_len/2]

corr_max_index = numpy.argmax(corr_mag_shifted_positive)
print 'number of samples in delay: ' + str(corr_max_index)
speed_of_light = 299792458.0 # m/s
feet_per_meter = 3.28084 # ft/m
delay_time = (1/bw_in_hz) * corr_max_index
delay_length_in_meters = delay_time * speed_of_light
delay_length_in_feet = delay_length_in_meters * feet_per_meter
print 'delay length: ' + str(int(delay_length_in_meters)) + 'm (' + str(int(delay_length_in_feet)) + 'ft)'

corr_x_axis_step = 1.0 / bw_in_hz
corr_x_axis_label = -1 * (corr_len/2) * corr_x_axis_step
x_axis_for_corr = []
for val in reference_array:
  x_axis_for_corr.append(corr_x_axis_label)
  corr_x_axis_label = corr_x_axis_label + corr_x_axis_step

plt.figure(4)
plt.title('Correlation Result')
plt.subplot(211)
plt.title('First 100 Samples in the Positive Delay Region')
plt.axis([0,100,min(corr_mag_shifted_positive),max(corr_mag_shifted_positive)])
plt.plot(corr_mag_shifted_positive)
plt.subplot(212)
plt.title('All Samples')
plt.plot(x_axis_for_corr, corr_mag_shifted)
plt.tight_layout()
plt.show()

