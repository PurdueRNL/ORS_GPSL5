% Clear command window and close any open popups
clc;
close all;

%%% INPUTS %%%
sampleFreq = 4000000; % Sampling frequency
intermediateFreq = 0000000; % Intermediate frequency
integrationTime = 0.001; % Integration time (seconds)
stepSize = 333; % Doppler step size
minDoppler = -5000; % Maximum doppler
maxDoppler = 5000;  % Minimum doppler
dataFile = '/home/rnl_lab/Desktop/XMTest_20160820212108.dat';
cpuType = 'int16'; % CPU type of data

% Compute constants
sampleAmount = floor(sampleFreq * integrationTime); 
pfile = fopen(dataFile);
stepAmount = ceil((maxDoppler - minDoppler) / stepSize);
chipSamples = ceil(sampleFreq / 1023000);

% Initialize vectors (for speed)
sampleI = zeros(1, sampleAmount);
sampleQ = zeros(1, sampleAmount);
Sample = zeros(1, sampleAmount);
dopplerShift = zeros(1, stepAmount);
localI = zeros(1, sampleAmount);
localQ = zeros(1, sampleAmount);
sortedCorr = zeros(sampleAmount, stepAmount);
rawCorrMax = zeros(1, stepAmount);
rawCorrMaxLoc = zeros(1, stepAmount);

for i = 1:sampleAmount
    sampleBuffer = fread(pfile, 2, cpuType); % Read I and Q components of one sample
    sampleI(i) = sampleBuffer(1); % I components of all samples 
    sampleQ(i) = sampleBuffer(2); % Q components of all samples
end

for PRN = 1:32
    CAcode = caGen(PRN); % Generate CA code
    CAcode = CAcode * 2 - 1;

    for i = 1:sampleAmount % Sample CA code  
        n = ceil(i * 1023000 / sampleFreq);
        n = n - 1023 * floor(n / 1023);
        
        if (n == 0)
            n = 1023;
        end
        
        Sample(i) = CAcode(n);
    end

    for i = 1:stepAmount
        dopplerShift(i) = -5000 + stepSize * i;
    
        for j = 1:sampleAmount
            % generate local replica of I and Q 
            localI(j) = 2^0.5 * cos(2 * pi * (intermediateFreq + dopplerShift(i)) * j / sampleFreq) * Sample(j);
            localQ(j) = 2^0.5 * sin(2 * pi * (intermediateFreq + dopplerShift(i)) * j / sampleFreq) * Sample(j);
        end
        
        % correlation of complex signals, could be simplified by directly representing the complex number by I+li*Q    
        [corrII] = circcorr(sampleI, localI);
        [corrQQ] = circcorr(sampleQ, localQ);
        [corrIQ] = circcorr(sampleI, localQ);
        [corrQI] = circcorr(sampleQ, localI);
        rawCorr = (corrII + corrQQ) .^ 2 + (-corrIQ + corrQI) .^ 2;
        sortedCorr(i, 1:sampleAmount) = rawCorr;
        [rawCorrMax(i), rawCorrMaxLoc(i)] = max(rawCorr);
    end

    [peak, peakLoc] = max(rawCorrMax);

    peakEdgeL = rawCorrMaxLoc(peakLoc) - chipSamples;
    peakEdgeR = rawCorrMaxLoc(peakLoc) + chipSamples;
    
    if peakEdgeL < 1
        peakEdgeL = peakEdgeL + sampleAmount;
        peakValue = sortedCorr(peakLoc, peakEdgeR:peakEdgeL);
    elseif peakEdgeR > sampleAmount
        peakEdgeR = peakEdgeR - sampleAmount;
        peakValue = sortedCorr(peakLoc, peakEdgeR:peakEdgeL);
    else
        peakValue = sortedCorr(peakLoc, [1:peakEdgeL, peakEdgeR:sampleAmount]);  
    end

    peakAvg = mean(peakValue);
    CN0 = 10 * log10(peak / (peakAvg * integrationTime));
    disp(CN0);

    [X, Y] = meshgrid(0:1023000 / sampleFreq:integrationTime * 1023000 - 1023000 / sampleFreq, minDoppler:stepSize:maxDoppler);
    figure
%     mesh(X, Y, sortedCorr);
% %     mesh(sortedCorr);
%     xlabel('Delay/chip');
%     ylabel('Doppler/Hz');
%     zlabel('Correlation');
%     t1 = strcat('Correlation for PRN', num2str(PRN));
%     title(t1);
%     xlim([0 integrationTime * 1023000]);
%     ylim([minDoppler maxDoppler]);
end