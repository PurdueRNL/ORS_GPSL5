function verification(cppfile1, cppfile2, samp_rate)

freq_c = 2.3432e9;
load('Data/XMBANDPASS8MHZ.mat')
filt = XMBandpassLow;

alldata_o = data_load_cpp(cppfile1, cppfile2, 'int16');
alldata = data_filter(alldata_o, filt);

[R, lag] = circcorr(alldata(:,1)', alldata(:,2)',1/samp_rate);
[R_plot, lag_plot] = plot_cut(R, lag, 50);

decim = 5000;
dat_fft1 = fftshift(abs(fft(alldata_o(:,1)')));
dat_fft1n = decimate(dat_fft1,decim);
dat_fft2 = fftshift(abs(fft(alldata_o(:,2)')));
dat_fft2n = decimate(dat_fft2,decim);

f = (1:size(dat_fft1,2)) + (freq_c-samp_rate/2);
fn = decimate(f,decim);

figure()
plot(lag_plot, abs(R_plot))

figure()
plot(fn, dat_fft1n)
hold all
plot(fn, dat_fft2n)

end





%  FFFFFFFFF  U       U  N       N   CCCCCCCC  TTTTTTTTT  IIIIIIIII   OOOOOOO   N       N   SSSSSSS 
%  F          U       U  NN      N  C              T          I      O       O  NN      N  S        
%  F          U       U  N N     N  C              T          I      O       O  N N     N  S        
%  F          U       U  N  N    N  C              T          I      O       O  N  N    N  S        
%  FFFFF      U       U  N   N   N  C              T          I      O       O  N   N   N   SSSSSSS 
%  F          U       U  N    N  N  C              T          I      O       O  N    N  N          S
%  F          U       U  N     N N  C              T          I      O       O  N     N N          S
%  F          U       U  N      NN  C              T          I      O       O  N      NN          S
%  F           UUUUUUU   N       N   CCCCCCCC      T      IIIIIIIII   OOOOOOO   N       N   SSSSSSS 



function [R, lag] = circcorr(x, y, Ts)
%
% Circular correlation of two vectors, x and y, through FFT methods. 
% 
% Output is R(lag), where R is the cross correlation of x and y and 
%  Lag is in the same dimensions as Ts.
%
% Prof. Jim Garrison, Purdue University, AAE575 Fall 2009
%
% Modified by Ian Bennett to accept row vectors x and y instead 
% of column vectors x and y
%
npts = size(x,2);
X = fft(x);
Y = fft(y);
FTXY = X.*conj(Y);
R = fftshift(ifft(FTXY))/npts;
lag = (-floor(npts/2):floor((npts-1)/2))*Ts;
return
end


function data1 = data_filter(alldata, filt)

data1 = zeros(size(alldata));
for ct = 1:size(alldata,2)
    data1(:,ct) = filter(filt, alldata(:,ct));
end

end


function [alldata] = data_load_cpp(file1, file2, samp_type)
% Read data files

fid_dat_A = fopen(file1);
fid_dat_B = fopen(file2);

dat_A = fread(fid_dat_A, [2, inf], samp_type);
dat_A = dat_A';
dat_B = fread(fid_dat_B, [2, inf], samp_type);
dat_B = dat_B';

A = dat_A(:,1) + dat_A(:,2)*1i;
B = dat_B(:,1) + dat_B(:,2)*1i;

alldata = [A, B];
fclose all;
end


function [R_plot, lag_plot] = plot_cut(R, lag, pw)
[~, ind] = max(abs(R));
R_plot = R(ind-pw:ind+pw);
lag_plot = lag(ind-pw:ind+pw);

end

