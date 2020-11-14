function [] = Extract_OutputTXT(filename)
% EXTRACT_OUTPUTTXT Converts a Wireshark capture to "Output.txt" 
%   Processes raw wireshark capture and creates Output.txt by keeping only three columns: Packet ID, Arrival time and packet size. Output.txt is processed by other functions that extract statistical data based on interarrivals and packet sizes.
%   TODO: Remove space behind fist column.
 
fid = fopen(filename,'r');

if fid == -1
    error('Error while opening Traffic file.');
end

outputTXT = fopen('Output.txt','w');
tline = fgets(fid);
n=0;

while ischar(tline)
    n = n + 1;
    tline = strsplit(tline);
    Packet_ID = str2double(char(tline(1)));
    Arrival_Time = str2double(char(tline(2)));
    Packet_Size = str2double(char(tline(6)));
    
    fprintf(outputTXT, '%d\t%f\t%d\n', Packet_ID, Arrival_Time, Packet_Size);		

    tline = fgets(fid);
end
fclose(outputTXT);
fclose(fid);

end