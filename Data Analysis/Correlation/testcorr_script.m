function testcorr_script(sig1,sig2,samp_rate,freq_c)
% Uses data files to analyze frequency spectrum and correlations of data
% previously recorded. Files should be in 16-bit complex format, and
% located in a single interleaved datafile, or in 32-bit float format in
% two data files.

%% Initialize
clc
fprintf('Loading data...\n')
close all
sig1 = 1;
sig2 = 2;
samp_rate = 8e6;
freq_c = 2.3432e9;

prefix = 'Data/';
alldata = data_load(strcat(prefix,'XMLHCP_nodelay.dat'), 'int16');
%alldata = data_load_cpp('Cpp/0usrp_samples.dat', 'Cpp/1usrp_samples.dat', 'int16');
%alldata = data_load_cpp('Cpp/0XMLHCP_nodelay.dat', 'Cpp/1XMLHCP_nodelay.dat', 'int16');

%% Filter/Condition Data
fprintf('Filtering/Conditioning data...\n')

%integration time (ms)
int_time = 1;

chunk_size = int_time * .001 * samp_rate;
numcycles = floor(size(alldata,1)/chunk_size);
numseconds = size(alldata,1)/samp_rate;

%Cut down data appropriately
alldata = alldata(1:chunk_size*numcycles,:);

%Load filters
load(strcat(prefix,'XMBANDPASS8MHZ.mat'))

%Filter data range
filter_type = 0;
if filter_type == 0
    XMfilt = XMBandpassLow;
elseif filter_type == 1
    XMfilt = XMBandpassUp;
else
    error('Unrecognized filter')
end

alldata_filter = data_filter(alldata, samp_rate, freq_c, XMfilt);



%% Split into coherent integration elements, correlate, and integrate

% Run correlations for 3 cases
[R, lag] = run_corr(samp_rate, chunk_size, numcycles, sig1, sig2, alldata_filter);



%% Narrow correlation range to be plotted
fprintf('Determining correlation peaks...\n')
pw = 20; %plot half-width

% Preallocate variables
corr_max = zeros(3,1);
max_ind = zeros(3,1);
R_plot = zeros(3,2*pw+1);
lag_plot = zeros(3,2*pw+1);

for ct = 1:3
    [corr_max(ct,1), max_ind(ct,1)] = max(R(ct,:));
    R_plot(ct,:) = R(ct, max_ind(ct,1)-pw : max_ind(ct,1)+pw);
    lag_plot(ct,:) = lag(ct, max_ind(ct,1)-pw : max_ind(ct,1)+pw);
end



%% Frequencies
fprintf('Analyzing frequency spectrum...\n')
decim = 5000;

%Allocate Space
dat_fft = zeros(size(alldata_filter,2), size(alldata_filter,1));
dat_fftn = zeros(size(alldata_filter,2), size(alldata_filter,1)/decim);
for ct = 1:size(alldata_filter,2)
    dat_fft(ct,:) = spec(alldata_filter(:,ct));
end

% Decimate fft for simplicity of plotting
fprintf('Decimating plot...\n')
for ct = 1:size(alldata_filter,2)
    dat_fftn(ct,:) = decimate(dat_fft(ct,:),decim);
end

f = (1:size(dat_fft,2))/numseconds + (freq_c-samp_rate/2);
fn = decimate(f,decim);



%% Generate Theoretical Autocorrelation
fprintf('Generating theoretical signals...\n')
[th_lag_plot, th_R_plot, m2] = XM_gen(samp_rate, numcycles, chunk_size, pw, XMfilt);



%% Plot Correlations
fprintf('Generating plots...\n')

%Determine which signals were correlated
switch sig1
    case 1
        sig_txt(1,:) = ' A';
    case 2
        sig_txt(1,:) = ' B';
    case 3
        sig_txt(1,:) = ' C';
    case 4
        sig_txt(1,:) = ' D';
end

switch sig2
    case 1
        sig_txt(2,:) = ' A';
    case 2
        sig_txt(2,:) = ' B';
    case 3
        sig_txt(2,:) = ' C';
    case 4
        sig_txt(2,:) = ' D';
end

t1 = strcat('Cross-correlation of signals', sig_txt(1,:), ' and', sig_txt(2,:), ' received');
t2 = strcat('Auto-correlation of signal', sig_txt(1,:), ' received');
t3 = strcat('Auto-correlation of signal', sig_txt(2,:), ' received');

figure()
subplot(3,1,1)
plot(lag_plot(1,:)*1e6, R_plot(1,:))
xlabel('Delay (microseconds)')
ylabel('Correlation Value')
title(t1)

subplot(3,1,2)
plot(lag_plot(2,:)*1e6, R_plot(2,:))
hold on
plot(th_lag_plot*1e6, th_R_plot/m2*corr_max(2,1), 'r-')
xlabel('Delay (microseconds)')
ylabel('Correlation Value')
title(t2)

subplot(3,1,3)
plot(lag_plot(3,:)*1e6, R_plot(3,:))
hold on
plot(th_lag_plot*1e6, th_R_plot/m2*corr_max(3,1), 'r-')
xlabel('Delay (microseconds)')
ylabel('Correlation Value')
title(t3)



%% Plot Frequencies
figure()
for ct = 1:size(alldata_filter,2)
    subplot(2,1,ct)
    plot(fn, dat_fftn(ct, :))
    switch ct
        case 1
            title('Signal A')
        case 2
            title('Signal B')
        case 3
            title('Signal C')
        case 4
            title('Signal D')
    end
    hold on
    vline(freq_c)
    vline(freq_c-samp_rate/2)
    vline(freq_c+samp_rate/2)
    grid on
    xlabel('Frequency (Hz)')
end

figure()
for ct = 1:size(alldata_filter,2)
    plot(fn, dat_fftn(ct, :))
    if ct == 1
        hold all
        title('Signals Received')
        grid on
        xlabel('Frequency (Hz)')
    end
    if ct == size(alldata_filter,2)
        vline(freq_c)
        vline(freq_c-samp_rate/2)
        vline(freq_c+samp_rate/2)
        legend('Signal A', 'Signal B')
    end
end



%% Final Output
fprintf('Done!\n')

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


function data1 = data_filter(alldata, samp_rate, freq_c, filt)

data1 = zeros(size(alldata));
for ct = 1:size(alldata,2)
    data1(:,ct) = filter(filt, alldata(:,ct));
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


function [R, lag] = run_corr(samp_rate, chunk_size, numcycles, sig1, sig2, alldata)

% Preallocate variables
R = zeros(3, chunk_size*2);
lag = zeros(3, chunk_size*2);
Rtemp = zeros(numcycles, chunk_size*2);
lagtemp = zeros(numcycles, chunk_size*2);
empty_mat = zeros(numcycles, chunk_size);

for ct = 1:3
    
    data_C_s = [reshape(alldata(:,sig1), chunk_size, [])' empty_mat];
    data_D_s = [reshape(alldata(:,sig2), chunk_size, [])' empty_mat];
    
    
    for ct2 = 1:numcycles
        switch ct
            case 1
                [Rtemp(ct2,:), lagtemp(ct2,:)] = circcorr(data_C_s(ct2,:), data_D_s(ct2,:), 1/samp_rate);
            case 2
                [Rtemp(ct2,:), lagtemp(ct2,:)] = circcorr(data_C_s(ct2,:), data_C_s(ct2,:), 1/samp_rate);
            case 3
                [Rtemp(ct2,:), lagtemp(ct2,:)] = circcorr(data_D_s(ct2,:), data_D_s(ct2,:), 1/samp_rate);
        end
        
        clc
        fprintf('Loading data...\nFiltering/Conditioning data...\n')
        fprintf('Processing correlation %d of 3, chunk number %d of %d\n', ct, ct2, numcycles)
        
    end
    
    %Incoherent averaging, so take the magnitude before averaging
    
    R(ct,:) = sum(abs(Rtemp), 1);
    lag(ct,:) = lagtemp(1,:);
    
end
end


function dat_fft = spec(data)

L = length(data);

fft_1 = fft(data);
fft_2 = abs(fft_1)/L;
dat_fft = fftshift(fft_2);
end


function hhh=vline(x,in1,in2)
% function h=vline(x, linetype, label)
% 
% Draws a vertical line on the current axes at the location specified by 'x'.  Optional arguments are
% 'linetype' (default is 'r:') and 'label', which applies a text label to the graph near the line.  The
% label appears in the same color as the line.
%
% The line is held on the current axes, and after plotting the line, the function returns the axes to
% its prior hold state.
%
% The HandleVisibility property of the line object is set to "off", so not only does it not appear on
% legends, but it is not findable by using findobj.  Specifying an output argument causes the function to
% return a handle to the line, so it can be manipulated or deleted.  Also, the HandleVisibility can be 
% overridden by setting the root's ShowHiddenHandles property to on.
%
% h = vline(42,'g','The Answer')
%
% returns a handle to a green vertical line on the current axes at x=42, and creates a text object on
% the current axes, close to the line, which reads "The Answer".
%
% vline also supports vector inputs to draw multiple lines at once.  For example,
%
% vline([4 8 12],{'g','r','b'},{'l1','lab2','LABELC'})
%
% draws three lines with the appropriate labels and colors.
% 
% By Brandon Kuczenski for Kensington Labs.
% brandon_kuczenski@kensingtonlabs.com
% 8 November 2001

if length(x)>1  % vector input
    for I=1:length(x)
        switch nargin
        case 1
            linetype='r:';
            label='';
        case 2
            if ~iscell(in1)
                in1={in1};
            end
            if I>length(in1)
                linetype=in1{end};
            else
                linetype=in1{I};
            end
            label='';
        case 3
            if ~iscell(in1)
                in1={in1};
            end
            if ~iscell(in2)
                in2={in2};
            end
            if I>length(in1)
                linetype=in1{end};
            else
                linetype=in1{I};
            end
            if I>length(in2)
                label=in2{end};
            else
                label=in2{I};
            end
        end
        h(I)=vline(x(I),linetype,label);
    end
else
    switch nargin
    case 1
        linetype='r:';
        label='';
    case 2
        linetype=in1;
        label='';
    case 3
        linetype=in1;
        label=in2;
    end

    
    
    
    g=ishold(gca);
    hold on

    y=get(gca,'ylim');
    h=plot([x x],y,linetype);
    if length(label)
        xx=get(gca,'xlim');
        xrange=xx(2)-xx(1);
        xunit=(x-xx(1))/xrange;
        if xunit<0.8
            text(x+0.01*xrange,y(1)+0.1*(y(2)-y(1)),label,'color',get(h,'color'))
        else
            text(x-.05*xrange,y(1)+0.1*(y(2)-y(1)),label,'color',get(h,'color'))
        end
    end     

    if g==0
    hold off
    end
    set(h,'tag','vline','handlevisibility','off')
end % else

if nargout
    hhh=h;
end
end


function [th_lag_plot, th_R_plot, m2] = XM_gen(samp_rate, numcycles, chunk_size, pw, XMfilt)
%Generates theoretical XM signal Autocorrelation

y = (rand(samp_rate,1)+1i*rand(samp_rate,1))';

sig = filter(XMfilt, y);
sigf = abs(fftshift(fft(sig)));
[~,ind] = max(abs(sigf));

sigf2 = fftshift(fft(sig));
sigf2(1,ind) = 0;
clear sig sigf y
sig2 = ifftshift(ifft(sigf2));

data_s = reshape(sig2, chunk_size, [])';
clear sig2 sigf2

for ct = 1:numcycles
    [R(ct,:), lag(ct,:)] = circcorr(data_s(ct,:), data_s(ct,:), 1/samp_rate);
end

th_R = sum(abs(R), 1);
th_lag = lag(1,:);

[m2, ind2] = max(th_R);

th_R_plot = th_R(1, ind2-pw:ind2+pw);
th_lag_plot = th_lag(1, ind2-pw:ind2+pw);

end

