filename = './Output.txt'; %Output.txt
Traffic1 = Calculate_Throughput(filename);

fprintf(' : %f Mbps\n', Traffic1);

function [Throughput] = Calculate_Throughput(filename)
	fid = fopen(filename,'r');
	if fid == -1
		error('Error while opening Traffic file.');
	end

	tline = fgets(fid);
	n=0;
	sum = 0;

	while ischar(tline)
		n = n + 1;
		tline = strsplit(tline);
		Current_Packet = str2double(char(tline(3)));
		sum = sum + Current_Packet;
		Last_Arrival_Time = str2double(char(tline(2)));

		tline = fgets(fid);
	end
	Throughput = (sum/Last_Arrival_Time)*8*10^(-6); %to Mbps
    
    fclose(fid);
end