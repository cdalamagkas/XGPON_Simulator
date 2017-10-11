function [ Event_List, Record_Mean_Delay_per_ONU] = Event5 ( Time, Event_List, Event5_Rate, Packet_Delay, Record_Mean_Delay_per_ONU, N, Arrivals )
% EVENT5 Reserved event
%  This event is reserved for debugging purposes
%
%  See also XGPON.

Record_Mean_Delay_per_ONU(:,end+1) = 0;
flag = false;

for i=1:N
   Result = Packet_Delay(i)/Arrivals(i);
   if isnan(Result)
      flag = true;
      continue;
   else
      Record_Mean_Delay_per_ONU(i,end) = Result;
   end
end

if flag
   Record_Mean_Delay_per_ONU(:,end)=[];
end

Event_List(1, end+1) = 5;
Event_List(2, end) = Time + Event5_Rate;
Event_List(3, end) = 3;

end
