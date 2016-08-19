% Clear workspace and command window
clear;
clc;

% Define (sub)header/footer demarcations
headerStart = double('HEADER ');
headerEnd = double(' HEADERX');
subheaderStart = double('SUBHEADER ');
subheaderEnd = double(' SUBHEADERX');
subfooterStart = double('SUBFOOTER ');
subfooterEnd = double(' SUBFOOTERX');

% Define file location
file = 'W:\Work\Test Data\L1_header.dat';

% Get a fileID
fileID = fopen(file);

% Place binary data into rawData variable
rawData = fread(fileID);

% Rotate rawData to be a vector instead of a column
rawData = rot90(rawData);

% Define (sub)header/footer sizes
headerSize = 1024;
subheaderSize = 1024;
subfooterSize = 1024;

% Find location of header start (to verify it's there)
headerStartLoc = strfind(rawData(1:1024), headerStart);

% Find location of header end
headerEndLoc = strfind(rawData, headerEnd);

% Find locations of subheader beginnings
subheaderStartLoc = strfind(rawData, subheaderStart);

% Find locations of subheader endings
subheaderEndLoc = strfind(rawData, subheaderEnd);

% Send data to heavy-lifting function
for i = 1:9
    correlate(rawData(subheaderEndLoc(i)):rawData(subheaderStartLoc(i+1)));
end

% Send last bit of data (the last section doesn't have a subheader after it
% to delineate it)
correlate(rawData(subheaderEndLoc(10)):rawData(length(rawData)));