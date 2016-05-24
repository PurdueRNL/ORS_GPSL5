% Read infomation from USRP output file format

fileheader = 'HEADER';
subheader = 'SUBHDR';
ender = 'ENDER';
savefile = strcat(path_extracted_data, data, '.mat');
% if (exist(savefile,'file'))
%     disp('mat file already exists!');
%     return;
% end
for ii=1:2
cd(path_data);
if (ii==1)
    path_file=[data '_1'];
else
    path_file=[data '_2'];
end
fid = fopen(path_file,'rb');
if (fid<0)
    disp('Data file not exist!');
    return;
end
cd(path_m);
file_head_buffer = zeros(1,6);

tmp_buffer1 = zeros(1,7);
tmp_buffer2 = zeros(1,80);
tmp_buffer3 = zeros(1,2);

% Find file header
while ~strcmp(file_head_buffer,fileheader)
    file_head_buffer = [file_head_buffer(2:end) fread(fid, 1, 'uint8=>char')];
end

% Read file info
file_info = fread(fid, 6, 'double');
% Read GPGGA
while ~strcmp(tmp_buffer1,'$GPGGA,')
    tmp_buffer1 = [tmp_buffer1(2:end) fread(fid, 1, 'uint8=>char')];
end
tmp1 = fread(fid, 64, 'uint8=>char');
gpsdata = textscan(tmp1,'%f,%f,%c,%f,%c,%d,%d,%f,%f,%c,%f,%c,%c,%c');
gpsdata_struct = convert2struct(gpsdata);
index = 1;
while ~strcmp(tmp_buffer3,ender)
    tmp_buffer2(index) = fread(fid, 1, 'uint8=>char');
    tmp_buffer3 = char([tmp_buffer3(2) tmp_buffer2(index)]);
    index = index + 1;
end
% Read GPS time
tmp2 = textscan(char(tmp_buffer2),'%16c %d');
gpsdata_struct.gpstime = cell2mat(tmp2(2));   

index_num = 1;
data_complex = zeros(file_info(2)*0.001,1);
sample_num=0;
% === Sub-section 1ms data=================================================
while ~feof(fid)
    sub_head_buffer = zeros(1,6);
    
    while 1
        sub_head_buffer = [sub_head_buffer(2:end) fread(fid, 1, 'uint8=>char')];    
        
        if feof(fid)
            break;
        elseif strcmp(sub_head_buffer,subheader)
            break;
        end
    end
    
    if feof(fid)
       break;
    end
    disp('OK')
    start_check(index_num) = 1;
    nsample(index_num) = fread(fid, 1, 'uint64=>double');
    end_tmp = fread(fid, 2, 'uint8=>char');
    if strcmp(end_tmp',ender)
        end_check(index_num) = 1;
        data_tmp = fread(fid, nsample(index_num)*2, 'int16=>double')';
%         data_complex(1:nsample(index_num),index_num) = data_tmp(1:2:end) + 1j*data_tmp(2:2:end);
%         data_complex2(sample_num+1:sample_num+nsample(index_num)) = data_tmp(1:2:end) + 1j*data_tmp(2:2:end);
        if (ii==1)
        I1(sample_num+1:sample_num+nsample(index_num))=data_tmp(1:2:end);
        Q1(sample_num+1:sample_num+nsample(index_num))=data_tmp(2:2:end);
        else    
        I2(sample_num+1:sample_num+nsample(index_num))=data_tmp(1:2:end);
        Q2(sample_num+1:sample_num+nsample(index_num))=data_tmp(2:2:end);
        end
        sample_num=sample_num+nsample(index_num);
    else
        end_check(index_num) = 0;
    end
    index_num = index_num + 1;
end
     
end
% === Sub-section 1ms data=================================================
  
  save(savefile,'I1','Q1','I2','Q2','file_info','gpsdata_struct','nsample');
  fclose('all');