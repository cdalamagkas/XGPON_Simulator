function [ Event_List, BWmap, CAT, BufOcc_Buffer, Load_Fairness, BWmap_Q, BWmap_Q_Index ] = Event1 ( Event_List, Time, BWmap, CAT, BufOcc_Buffer, Load_Fairness, Downstream_Transmission_Delay, D, Guard_Time, C, N, Upstream_Speed, PDT, PAS_Flag, BWmap_Q, BWmap_Q_Index)
% EVENT1 Creates and broadcasts downstream PHY frame
% 	Calls the DBA mechanism to create BWmap and then broadcasts the 
%  downstream PHY frame to ONUs. PHY frame arrival is represented 
%  by scheduling Event2. EVENT1 is strictly repeated each 125 usec.
%
%  See also DBA, EVENT2.

[ BWmap, CAT, BufOcc_Buffer, Load_Fairness ] = DBA ( Time, BufOcc_Buffer, BWmap, D, CAT, Downstream_Transmission_Delay, Guard_Time, C, N, Upstream_Speed, PDT, Load_Fairness, PAS_Flag );
%fprintf('#[%d]# New BWmap was created #\n', Time);

for ONU_ID = 1:N
	
    % BWmap_Q (FIFO) captures the version of BWmap that ONU should read.
    BWmap_Q_Index(ONU_ID) = BWmap_Q_Index(ONU_ID) + 1;
    BWmap_Q( 1, BWmap_Q_Index(ONU_ID), ONU_ID ) = BWmap( 1, ONU_ID );
    BWmap_Q( 2, BWmap_Q_Index(ONU_ID), ONU_ID ) = BWmap( 2, ONU_ID );
    BWmap_Q( 3, BWmap_Q_Index(ONU_ID), ONU_ID ) = BWmap( 3, ONU_ID );
    
    Event_List( 1, end + 1 ) = 2;
    Event_List( 2, end ) = Time + PDT(ONU_ID) + Downstream_Transmission_Delay;
    Event_List( 3, end ) = 2;
    Event_List( 4, end ) = ONU_ID;
    
    %fprintf('#1 BWmap scheduled for arrival to ONU_ID (%d) at time [%d]\n', ONU_ID, Event_List( 2, end ));
end

Event_List( 1, end + 1 ) = 1;
Event_List( 2, end ) = Time + 0.000125;
Event_List( 3, end ) = 2;
    
end
