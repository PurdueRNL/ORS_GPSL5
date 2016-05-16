% Clear command window and close any open figures
clc;
close all;

% Settings
fs = 50000000; % sampling frequency
fI = 0000000; % intermediate frequency
fD = 0;
Ti = 0.001; % integration time
sample_num = floor(fs*Ti);

% Open datafile
pfile = fopen('/home/rnl_lab/ORS_GPSL5/Data Gathering/Data/XMTest_20160516070959.dat');

xR = [];
xR2 = [];

% Read data from file
for i = 1:sample_num
    xR_temp = fread(pfile, 2, 'int8'); % Read I and Q components of one sample
    xR = [xR, xR_temp(1)]; % I components of all samples
    xR2 = [xR2, xR_temp(2)];% Q components of all samples
end

% Calculate correlation for each satellite
for PRN = 1:32
    CAcode = caGen(PRN); % generate CA code
    CAcode = CAcode*2-1;

    for i = 1:sample_num % sample the CA code    
        n = ceil(i*1023000/fs);
        n = n-1023*floor(n/1023);
        
        if (n == 0)
            n = 1023;
        end
        
        Sample(i) = CAcode(n);
    end

    step = 333; % doppler step size
    minFreq = -5000; % maximum doppler
    maxFreq = 5000;  % minimum doppler
    FreqBinNum = ceil((maxFreq-minFreq)/step);

    for i = 1:FreqBinNum
    
        fD(i) = -5000 + step * i;
    
        for j = 1:sample_num
            % generate local replica of I and Q 
            IL(j) = 2^0.5 * cos(2*pi*(fI+fD(i))*j / fs) * Sample(j);
            IQ(j) = 2^0.5 * sin(2*pi*(fI+fD(i))*j / fs) * Sample(j);
        end
        % correlation of complex signals, could be simplified by directly representing the complex number by I+li*Q    
        [RI_1, ~] = circcorr(xR, IL, 1023000/fs);
        [RI_2, ~] = circcorr(xR2, IQ, 1023000/fs);
        [RQ_1, ~] = circcorr(xR, IQ, 1023000/fs);
        [RQ_2, ~] = circcorr(xR2, IL, 1023000/fs);
        Z = (RI_1+RI_2) .^ 2 + (-RQ_1+RQ_2) .^ 2;
        R(i,1:sample_num) = Z;
        [m(i), index(i)] = max(Z);

    end

    [peak,freqBin] = max(m);

    SamplesPerChip = ceil(fs/1023000);
    a1 = index(freqBin) - SamplesPerChip;
    a2 = index(freqBin) + SamplesPerChip;
    if a1 < 1
        a1 = a1 + sample_num;
        b = R(freqBin, a2:a1);
    
    elseif a2 > sample_num
        a2 = a2 - sample_num;
        b = R(freqBin, a2:a1);    

    else
        b = R(freqBin,[1:a1, a2:sample_num]);  
    end

    N = mean(b);
    CN0 = 10*log10(peak/(N*Ti));
    disp(CN0);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % [X,Y]=meshgrid(0:1023000/fs:Ti*1023000-1023000/fs,minFreq:step:maxFreq);
    % figure;
    % mesh(X,Y,R);
    % xlabel('Delay/chip');
    % ylabel('Doppler/Hz');
    % zlabel('Correlation');
    % t1 = strcat('Correlation for PRN',num2str(PRN));
    % title(t1);
    % xlim([0 Ti*1023000]);
    % ylim([minFreq maxFreq]);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end