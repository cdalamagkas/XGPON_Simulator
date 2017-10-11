function [ Traffic ] = Form_Traffic( hasVBR, hasCBR )
% FORM_TRAFFIC Creates traffic objects based on user preferences
%  Returns traffic objects of CBR and VBR traffic that ONU use to generate 
%  traffic. User can edit manually the CBR traffic object parameters and
%  specify Output.txt files. Each Output.txt file corresponds to independent VBR traffic that a single ONU generates.
%
%  See also XGPON, EVENT7, RNG, EXTRACT_DISTRIBUTION

if ~hasVBR && ~hasCBR
	error('Some traffic must be enabled');
end

if hasVBR
    if ispc()
        filename = '.\Traffic\1\Output.txt';
        [Packet_Frequencies1, Interarrivals1] = Extract_Distribution(filename);
    else %for UNIX
        filename = './Traffic/1/Output.txt';
        [Packet_Frequencies1, Interarrivals1] = Extract_Distribution(filename);		 		 
    end
    Traffic1 = struct('packetfreq', Packet_Frequencies1, 'interarrivalfreq', Interarrivals1);
    VBR = struct('isenabled', true, 'traffic1', Traffic1);
else
    VBR = struct('isenabled', false);
end

if hasCBR
    CBR = struct('isenabled', true, 'interarrival', 0.00012096,'packetsize', 1512);
else
    CBR = struct('isenabled', false);
end

Traffic = struct('cbr', CBR, 'vbr', VBR);

end