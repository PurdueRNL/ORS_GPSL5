function testcorr_phase

clear
clc

disp('Loading Data')
samp_rate = 8e6;

%alldata = data_load('Data/XMLHCP_nodelay.dat', 'int16');
%alldata2 = data_load('Data/XMLHCP_delay.dat', 'int16');
alldata = data_load_cpp('Cpp/0XMLHCP_nodelay.dat', 'Cpp/1XMLHCP_nodelay.dat', 'int16');
alldata2 = data_load_cpp('Cpp/0XMLHCP_delay.dat', 'Cpp/1XMLHCP_delay.dat', 'int16');

load('Data/XMBANDPASS8MHZ.mat');
XMfilt = XMBandpassLow;
alldata = data_filter(alldata, XMfilt);
alldata2 = data_filter(alldata2, XMfilt);

disp('Correlating Data')
[R, lag] = circcorr(alldata(:,1)', alldata(:,2)', 1/samp_rate);
[R2, lag2] = circcorr(alldata2(:,1)', alldata2(:,2)', 1/samp_rate);

[~, I] = max(abs(R));
[~, I2] = max(abs(R2));
shift = abs(I-I2);

num = 1:1:399;
mult = 10000;
num = num*mult;

ave = zeros(size(num));

for pw = num
    
    min_ind = min([I-pw, I2-pw]);
    max_ind = max([I+pw, I2+pw]);
    
    ang = (angle(R2(min_ind-shift:max_ind-shift)) - angle(R(min_ind:max_ind)))'*180/pi;
    ave(pw/mult) = mean(ang);
    
    clc
    fprintf('Percent Complete %.2f\n', pw/num(end)*100)
    fprintf('Shift of %d\n', shift)
end

double_ave = mean(ave)

pw = 20;
min_ind = min([I-pw, I2-pw]);
max_ind = max([I+pw, I2+pw]);

figure()
plot(lag(min_ind:max_ind),angle(R(min_ind:max_ind))*180/pi, 'b-o')
hold on
plot(lag2(min_ind:max_ind),angle(R2(min_ind-shift:max_ind-shift))*180/pi, 'r-*')

figure()
plot(lag(min_ind:max_ind),abs(R(min_ind:max_ind)), 'b-o')
hold on
plot(lag2(min_ind:max_ind),abs(R2(min_ind-shift:max_ind-shift)), 'r-*')

figure()
plot(num, ave)

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


function data1 = data_filter(alldata, XMfilt)

% freq  = 2.342205e9;
% marg = 50e3;
% bandw = 1.866e6;
% F_stop1 = freq-freq_c-bandw/2-marg; %freq-freq_c-marg;
% F_pass1 = F_stop1+marg;
% F_pass2 = F_pass1+bandw;
% F_stop2 = F_pass2+marg; %F_stop1+1.866e6+2*marg;
% A_stop1 = 60;
% A_pass = .1;
% A_stop2 = A_stop1;
% 
% BandPassSpecObj = fdesign.bandpass('Fst1,Fp1,Fp2,Fst2,Ast1,Ap,Ast2', F_stop1, F_pass1, F_pass2, F_stop2, A_stop1, A_pass, A_stop2, samp_rate);
% 
% %designmethods(BandPassSpecObj)
% 
% BandPassFilt = design(BandPassSpecObj, 'cheby1');

%fvtool(BandPassFilt)
%error('Blah Blah Blah');

data1 = zeros(size(alldata));
for ct = 1:size(alldata,2)
    data1(:,ct) = filter(XMfilt, alldata(:,ct));
end

end


function [alldata] = data_load(file1, samp_type)
% Read data files

fid_dat = fopen(file1);
dat = fread(fid_dat, [4, inf], samp_type);
dat = dat';
A = dat(:,1) + dat(:,2)*1i;
B = dat(:,3) + dat(:,4)*1i;

alldata = [A, B];
fclose all;
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

