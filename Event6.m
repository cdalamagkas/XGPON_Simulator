function [ Event_List, Serial_Number, Q, Q_Index, Buffer_Occupancy, Packet_Loss ] = Event6 ( Time, Event_List, Serial_Number, Q, Q_Index, Buffer_Occupancy, Buffer_Size, Packet_Loss, CBR )
% EVENT6 Packet arrival (CBR)
%  EVENT6 adds a new packet to AllocID's queue, based on the CBR traffic 
%  struct input.
% 	
% See also EVENT2, EVENT7, RNG.
    
AllocID = Event_List(4,1);
%fprintf('[%d] #6 New packet to AllocID (%d)\n', Time, AllocID);

if Buffer_Occupancy(AllocID) + CBR.packetsize < Buffer_Size
    Q_Index( AllocID ) = Q_Index( AllocID ) + 1;
    Q( 1, Q_Index(AllocID), AllocID ) = Serial_Number;
    Q( 2, Q_Index(AllocID), AllocID ) = Time;
    Q( 3, Q_Index(AllocID), AllocID ) = CBR.packetsize;
    Serial_Number = Serial_Number + 1;
	
    Buffer_Occupancy(AllocID) = Buffer_Occupancy(AllocID) + CBR.packetsize;
	
    Event_List( 1, end + 1 ) = 6;
    Event_List( 2, end ) = Time + CBR.interarrival;
    Event_List( 3, end ) = 1;
    Event_List( 4, end ) = AllocID;
else
    %fprintf('WARNING! Packet was dropped\n');
    Packet_Loss(1, AllocID) = Packet_Loss(1, AllocID) + 1;
end

end
