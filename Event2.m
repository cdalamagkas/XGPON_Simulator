function [ Event_List, Q, Q_Index, BWmap_Q, BWmap_Q_Index, Buffer_Occupancy ] = Event2 ( Time, Event_List, Q, Q_Index, BWmap_Q, Upstream_Speed, PDT, BWmap_Q_Index, Buffer_Occupancy )
% EVENT2 Schedule XGTC burst
%  Responds to a received BWmap. Upon BWmap arrival, ONU forms it's DBRu 
%  and allocation payload based on it's queue and GrantSize of the received
%  BWmap. Finally, ONU sends the burst by scheduling Event3.
%
%  See also EVENT1, EVENT3, EVENT6, EVENT7.
	
AllocID = Event_List(4,1);
%fprintf('[%d] #2 BWmap arrived to AllocID (%d).\n', Time, AllocID );

%% Take the right version of BWmap
StartTime = BWmap_Q( 2, 1, AllocID );
GrantSize = BWmap_Q( 3, 1, AllocID ); 

for i = 1 : BWmap_Q_Index(AllocID)-1
   BWmap_Q( : , i, AllocID ) = BWmap_Q( :, i+1, AllocID );
end
BWmap_Q( :, BWmap_Q_Index(AllocID), AllocID ) = 0; 
BWmap_Q_Index(AllocID) = BWmap_Q_Index(AllocID) - 1; 

%% Form allocation payload 
Data_Size = 0;
Number_of_Packets = 0;
Available_XGTC_Payload = GrantSize - 4; %DBRu+CRC is reserved as allocation overhead
Total_Padding = 0;

Event_List( 1, end + 1 ) = 3;

if Q_Index(AllocID) > 0
   %% Select packets
   for i = 1 : Q_Index(AllocID)
      if Available_XGTC_Payload >= Q(3, i, AllocID) + 8
         if Q(3, i, AllocID) < 8
            Data_Size = Data_Size + 8;
            Padding = 8 - Q(3, i, AllocID);
            Available_XGTC_Payload = Available_XGTC_Payload - 16;
            Total_Padding = Total_Padding + Padding;
         else
            Data_Size = Data_Size + Q(3, i, AllocID);
            Available_XGTC_Payload = Available_XGTC_Payload - Q(3, i, AllocID) - 8;
         end
         Number_of_Packets = Number_of_Packets + 1;
      elseif Available_XGTC_Payload >= 16 && Available_XGTC_Payload < Q(3, i, AllocID) + 8
         Fragment = Available_XGTC_Payload - 8;
         Data_Size = Data_Size + Fragment;         
         Q( 3, i, AllocID ) = Q( 3, i, AllocID ) - Fragment;
         break; 
      end 
   end
   %% Remove sending packets from queue
   Event_List( 7, end ) = Number_of_Packets;
   for counter = 1:Number_of_Packets
      Event_List( 7+counter, end ) = Q( 2, 1, AllocID );
      Q( :, 1, AllocID ) = 0;
      for i = 1 : Q_Index(AllocID)-1
         Q( :, i, AllocID ) = Q( :, i+1, AllocID );
      end
      Q( :, Q_Index(AllocID), AllocID ) = 0;
      Q_Index(AllocID) = Q_Index(AllocID) - 1;
    end
   %% Refresh buffer occupancy of AllocID
   Buffer_Occupancy(AllocID) = Buffer_Occupancy(AllocID) - Data_Size - Total_Padding;   
end

%% Create final PHY burst and schedule it's arrival
PHY_Burst  = 24 + PHY_Payload(GrantSize);

Event_List( 2, end ) = Time + StartTime + PHY_Burst/Upstream_Speed + PDT(AllocID);
Event_List( 3, end ) = 2;
Event_List( 4, end ) = AllocID;
Event_List( 5, end ) = Data_Size - Total_Padding; % Payload sent
Event_List( 6, end ) = Buffer_Occupancy(AllocID);

%fprintf('\t PHY burst size: %d. Allocation payload: %d\n', PHY_Burst, Data_Size);
end
