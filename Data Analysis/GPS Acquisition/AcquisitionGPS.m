clc;
% clear all;
close all;
% [X,Y] = meshgrid(-8:.5:8);

% GPS
fs=4000000;% sampling frequency
fI=0000000;% intermediate frequency
fD=0;
Ti=0.001;% integration time
sample_num=floor(fs*Ti); 
pfile=fopen('C:\Users\rnllab\Desktop\NRL_Testing\Test_5_GPS_RL\GPSRL_20160216T182352Z_1');
xR=[];
xR2=[];
for i=1:sample_num
xR_temp=fread(pfile,2,'int16'); % Read I and Q components of one sample
xR=[xR xR_temp(1)]; % I components of all samples 
xR2=[xR2 xR_temp(2)];% Q components of all samples
end
% load('C:\Users\rnllab\Downloads\matlab4\matlab1')
% xR(1:sample_num)=data_I(sample_num*40.5+1:sample_num*41.5);
% xR2(1:sample_num)=data_Q(sample_num*40.5+1:sample_num*41.5);
% data_I=real(data_complex);
% data_Q=imag(data_complex);
% xR(1:sample_num)=data_I(sample_num*40.5+1:sample_num*41.5);
% xR2(1:sample_num)=data_Q(sample_num*40.5+1:sample_num*41.5);

% psd(data_complex);
for PRN=1:32
CAcode=caGen(PRN); % generate CA code
CAcode=CAcode*2-1;

for i=1:sample_num % sample the CA code    
n=ceil(i*1023000/fs);
n=n-1023*floor(n/1023);
if (n==0)
    n=1023;
end
Sample(i)=CAcode(n);
end

step=333; % doppler step size
minFreq=-5000; % maximum doppler
maxFreq=5000;  % minimum doppler
FreqBinNum=ceil((maxFreq-minFreq)/step);

for i=1:FreqBinNum
    
fD(i)=-5000+step*i;
    
for j=1:sample_num
% generate local replica of I and Q 
IL(j)=2^0.5*cos(2*pi*(fI+fD(i))*j/fs)*Sample(j);
IQ(j)=2^0.5*sin(2*pi*(fI+fD(i))*j/fs)*Sample(j);
end
% correlation of complex signals, could be simplified by directly representing the complex number by I+li*Q    
[RI_1, lag]= circcorr(xR,IL,1023000/fs);
[RI_2, lag]= circcorr(xR2,IQ,1023000/fs);
[RQ_1, lag]= circcorr(xR,IQ,1023000/fs);
[RQ_2, lag]= circcorr(xR2,IL,1023000/fs);
Z=(RI_1+RI_2).^2+(-RQ_1+RQ_2).^2;
R(i,1:sample_num)=Z;
[m(i),index(i)]=max(Z);

end

[peak,freqBin]=max(m);

SamplesPerChip=ceil(fs/1023000);
a1=index(freqBin)-SamplesPerChip;
a2=index(freqBin)+SamplesPerChip;
if a1<1
    a1=a1+sample_num;
    b=R(freqBin,a2:a1);
    
elseif a2>sample_num
    a2=a2-sample_num;
    b=R(freqBin,a2:a1);    

else
    b=R(freqBin,[1:a1,a2:sample_num]);  
end

N=mean(b);
CN0=10*log10(peak/(N*Ti));
% CN0=0;
disp(CN0);

[X,Y]=meshgrid(0:1023000/fs:Ti*1023000-1023000/fs,minFreq:step:maxFreq);
figure
mesh(X,Y,R);
xlabel('Delay/chip');
ylabel('Doppler/Hz');
zlabel('Correlation');
t1 = strcat('Correlation for PRN',num2str(PRN));
title(t1);
xlim([0 Ti*1023000]);
ylim([minFreq maxFreq]);
end





