clear
clc
close all

pw = 5:5:40;

for ct = pw
    
    ang(ct/5) = testcorr_phase(ct);
    clc
    disp(ct/pw(end)*100)
end

figure()
plot(pw,ang)
grid on