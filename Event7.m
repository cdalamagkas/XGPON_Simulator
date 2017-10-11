function [ Event_List, Serial_Number, Q, Q_Index, Buffer_Occupancy, Packet_Loss ] = Event7 ( Time, Event_List, Serial_Number, Q, Q_Index, Buffer_Occupancy, Buffer_Size, Packet_Loss, VBR )
% EVENT7 Packet arrival (VBR)
%  Adds a new packet to AllocID's queue, based on the VBR traffic 
%  struct input.
% 	
% See also EVENT2, EVENT6, FORM_TRAFFIC, EXTRACT_DISTRIBUTION.
    
AllocID = Event_List(4,1);
Packet_Size = RNG(VBR.packetfreq);

%fprintf('#7+ New packet to AllocID (%d) at time [%d]\n', AllocID, Time);

if Buffer_Occupancy(AllocID) + Packet_Size < Buffer_Size
    Q_Index( AllocID ) = Q_Index( AllocID ) + 1;
    Q( 1, Q_Index(AllocID), AllocID ) = Serial_Number;
    Q( 2, Q_Index(AllocID), AllocID ) = Time;
    Q( 3, Q_Index(AllocID), AllocID ) = Packet_Size;
    Serial_Number = Serial_Number + 1;
    
    Buffer_Occupancy(AllocID) = Buffer_Occupancy(AllocID) + Packet_Size;
    
    Event_List( 1, end + 1 ) = Event_List(1, 1);
    Event_List( 2, end ) = Time + RNG(VBR.interarrivalfreq);
    Event_List( 3, end ) = 1;
    Event_List( 4, end ) = AllocID;
else
    %fprintf('WARNING! Packet was dropped\n);
    Packet_Loss(1, AllocID) = Packet_Loss(1, AllocID) + 1;
end

end