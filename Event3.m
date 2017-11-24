function [ BufOcc_Buffer, Total_Data, Packet_Delay, Arrivals, PDV ] = Event3 ( Time, Event_List, BufOcc_Buffer, Total_Data, Packet_Delay, Arrivals, PDV )
% EVENT3 XGTC burst arrives at the OLT
%	OLT receives a XGTC burst, which is sent by Event2. Upon the arrival, 
%  OLT records information that are used to measure throughput, mean packet
%  delay and packet delay variation (PDV).
%
%  See also EVENT2.

AllocID = Event_List(4,1);
%fprintf('[%d] #3 XGTC frame arrival [%d bytes] from AllocID (%d)\n', Time, Event_List(5,1), AllocID);

Total_Data = Total_Data + Event_List(5,1);
BufOcc_Buffer(AllocID) = BufOcc_Buffer(AllocID) + Event_List(6,1);
	
Number_of_Packets = Event_List(7,1);
Arrivals(AllocID) = Arrivals(AllocID) + Number_of_Packets;

for i = 1:Number_of_Packets
   Delay = (Time - Event_List(7+i, 1));
   Packet_Delay(1, AllocID) = Packet_Delay(1, AllocID) + Delay; %Sum delays
   if PDV(1, AllocID)
      PDV(3, AllocID) = Delay;
      PDV(4, AllocID) = PDV(4, AllocID) + abs(PDV(2, AllocID) - PDV(3, AllocID));
      PDV(5, AllocID) = PDV(5, AllocID) + 1;
      PDV(2, AllocID) = PDV(3, AllocID);
   else
      PDV(1, AllocID) = 1;
      PDV(2, AllocID) = Delay;
   end
end

end
