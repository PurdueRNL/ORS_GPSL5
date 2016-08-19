
function main()
file1='XMLHCP_20150103134728_A.dat';
file2='XMLHCP_20150103134728_A_new.dat';
data_load_cpp(file1, file2, 'int16');
end

function [alldata] = data_load_cpp(file1, file2, samp_type)
% Read data files

fid_dat_A = fopen(file1);
fid_dat_B = fopen(file2,'w');

dat_A = fread(fid_dat_A, [2, inf], samp_type);
dat_A = dat_A';


A = dat_A(:,1);


fwrite(fid_dat_B,A,samp_type);
fclose all;
end