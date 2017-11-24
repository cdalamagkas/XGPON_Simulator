function [ Packet_Delay, Goodput, Load_Fairness, Delay_Fairness, Packet_Loss_Ratio, PDV, Record_Mean_Delay_per_ONU ] = XGPON( Sim_Time, D, N, PDT, Traffic, PAS_Flag )
% XGPON Main XG-PON event-driven simulator
%  Simulates the upstream channel of an ITU-T G.987 XG-PON1 network and 
%  exports network statistics. All simulation parameters and definitions
%  are expressed in bytes and seconds.
%  
% See also FORM_TRAFFIC, SET_PDT.

%% System constants
Upstream_Speed = 311040000;
Downstream_Transmission_Delay = 0.000125;
C = 38880 - 24*N;
Guard_Time = 2.57201646e-8;

%% BWmap related variables
BufOcc_Buffer = zeros(1,N);
BWmap = zeros(3,N); %AllocID, StartTime, GrantSize
BWmap_Q = zeros(3,0,N); %Keeps BWmap that each ONU should read first.
BWmap_Q_Index = zeros(1,N);
CAT = 0;

%% Data packet queue
Serial_Number = 1;
Q = zeros(3,0,N); % packet_id, time entered in Q, size in bytes
Q_Index = zeros(1,N);
Buffer_Occupancy = zeros(1, N);
Buffer_Size = Inf; % Bytes
Padding = zeros(1, N);

%% Variables for network metrics
Total_Data = 0; %Bytes
Packet_Delay = zeros(1,N);
PDV = zeros(5,N); % 1. not the first in steam? 2. delay of first packet, 3. delay of second packet, 4. PDV accumulator, 5. PDV counter 
Packet_Loss = zeros(1,N);
Arrivals = zeros(1,N);
Load_Fairness = zeros(2,1); %Jain's load fairness index

%% Event_List initialization
Event_List = zeros(7,0);

if Traffic.vbr.isenabled % VBR traffic(s) initialization
    fields = fieldnames(Traffic.vbr);
    Number_of_VBR_Traffics = length(fields)-1;
    for k = 1:Number_of_VBR_Traffics
        for i = 1:N
            Event_List(1, end + 1) = 6+k;
            Event_List(2, end) = 0;
            Event_List(3, end) = 1;
            Event_List(4, end) = i;
        end
    end
end
if Traffic.cbr.isenabled % CBR traffic initialization
    for i = 1:N
        Event_List(1, end + 1) = 6;
        Event_List(2, end) = 0;
        Event_List(3, end) = 1;
        Event_List(4, end) = i;
    end
end

Event_List(1, end + 1) = 1; 
Event_List(2, end) = 0;
Event_List(3, end) = 2;

Event_List(1, end + 1) = 4;
Event_List(2, end) = Sim_Time;
Event_List(3, end) = 5;

%% Optional Event 5 initialization for debugging purposes
Record_Mean_Delay_per_ONU = zeros(N,0);
Event5_Rate = Sim_Time/100;
Event_List(1, end + 1) = 5;
Event_List(2, end) = 0;
Event_List(3, end) = 3;

%% Event_List main loop
Sim_Flag = true;
while Sim_Flag
   Event = Event_List(1,1);
   Time = Event_List(2,1);
   if Event == 1 % "Create and broadcast" BWmap
      [ Event_List, BWmap, CAT, BufOcc_Buffer, Load_Fairness, BWmap_Q, BWmap_Q_Index ] = Event1 ( Event_List, Time, BWmap, CAT, BufOcc_Buffer, Load_Fairness, Downstream_Transmission_Delay, D, Guard_Time, C, N, Upstream_Speed, PDT, PAS_Flag, BWmap_Q, BWmap_Q_Index);
   elseif Event == 2 % Send XGTC burst
      [ Event_List, Q, Q_Index, BWmap_Q, BWmap_Q_Index, Buffer_Occupancy ] = Event2 ( Time, Event_List, Q, Q_Index, BWmap_Q, Upstream_Speed, PDT, BWmap_Q_Index, Buffer_Occupancy );
   elseif Event == 3 % XGTC burst arrival
      [ BufOcc_Buffer, Total_Data, Packet_Delay, Arrivals, PDV ] = Event3 ( Time, Event_List, BufOcc_Buffer, Total_Data, Packet_Delay, Arrivals, PDV );
   elseif Event == 4 % Termination event
      [ Sim_Flag, Packet_Delay, Goodput, Load_Fairness, Delay_Fairness, Packet_Loss_Ratio, PDV ] = Event4 ( Time, Packet_Delay, Total_Data, Load_Fairness, N, Arrivals, Packet_Loss, PDV );
   elseif Event == 5 % Reserved Event for debugging
      [ Event_List, Record_Mean_Delay_per_ONU] = Event5 ( Time, Event_List, Event5_Rate, Packet_Delay, Record_Mean_Delay_per_ONU, N, Arrivals );
   elseif Event == 6 % CBR Traffic
      [ Event_List, Serial_Number, Q, Q_Index, Buffer_Occupancy, Packet_Loss ] = Event6 ( Time, Event_List, Serial_Number, Q, Q_Index, Buffer_Occupancy, Buffer_Size, Packet_Loss, Traffic.cbr );
   else % VBR Traffic events in range [7, Inf]
      [ Event_List, Serial_Number, Q, Q_Index, Buffer_Occupancy, Packet_Loss ] = Event7 ( Time, Event_List, Serial_Number, Q, Q_Index, Buffer_Occupancy, Buffer_Size, Packet_Loss, Traffic.vbr.(fields{(Event-6)+1}) );
   end
   Event_List(:,1)=[];
   Event_List=(sortrows(Event_List',[2,3]))';
end
end