function [Packet_Frequencies, Interarrivals] = Extract_Distribution(filename)
% EXTRACT_DISTRIBUTION Forms the componets of a traffic object
%  Reads Output.txt file of a Wireshark capture and
%  records frequences of packet sizes and interarrival times. 
%  INPUT: Relative or absolute path of Output.txt
%  OUTPUT: Sorted distribution tables of packet sizes and interarrivals
%  REQUIREMENTS: Output.txt must be a timeseries of three columns: 
%   packet id, arrival time and packet size, spaced by tab.
%
% See also FORM_TRAFFIC, EVENT7, RNG.

Packet_Frequencies = zeros(2,0); Interarrivals = zeros(2,0);

fid = fopen(filename,'r');
if fid == -1
	error('Error while opening Traffic file.');
end

tline = fgets(fid); %Read first line to initialize metrics
tline = strsplit(tline);
Packet_Frequencies(1,end+1) = str2double(char(tline(3)));
Packet_Frequencies(2,end) = 1;

Previous_Arrival = str2double(char(tline(2)));

tline = fgets(fid); %Read next line

while ischar(tline)
    tline = strsplit(tline);
    Current_Packet = str2double(char(tline(3)));
    Current_Interarrival = str2double(char(tline(2))) - Previous_Arrival;
	
    i = find(Packet_Frequencies(1,:) == Current_Packet);
    if isempty(i)
        Packet_Frequencies(1,end+1) = Current_Packet;
        Packet_Frequencies(2,end) = 1;
    else
        Packet_Frequencies(2,i) = Packet_Frequencies(2,i) + 1;
    end
	
    i = find(Interarrivals(1,:) == Current_Interarrival);
    if isempty(i)
        Interarrivals(1,end+1) = Current_Interarrival;
        Interarrivals(2,end) = 1;
    else
        Interarrivals(2,i) = Interarrivals(2,i) + 1;
    end
	
    Previous_Arrival = str2double(char(tline(2)));
    tline = fgets(fid);
end

Packet_Frequencies(2,:) = Packet_Frequencies(2,:)./length(Packet_Frequencies);
Interarrivals(2,:) = Interarrivals(2,:)./length(Interarrivals);

Packet_Frequencies = sortrows(Packet_Frequencies',2)';
Interarrivals = sortrows(Interarrivals',2)';

fclose(fid);

end