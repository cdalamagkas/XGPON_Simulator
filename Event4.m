function [ Sim_Flag, Packet_Delay, Goodput, Load_Fairness, Delay_Fairness, Packet_Loss, PDV ] = Event4 ( Time, Packet_Delay, Total_Data, Load_Fairness, N, Arrivals, Packet_Loss, PDV )
% EVENT4 Termination Event
%  Termination event is called when simulation time ends. The final network
%  metrics are being calculated: mean packet delay per ONU, mean packet 
%  delay variation per ONU, mean packet loss ratio, mean network goodput, 
%  and delay fairness index.
%
% See also XGPON.

Sim_Flag = false;
%fprintf('Simulation end at time [%f]',Time) 

PDV(1,:) = [];
PDV(1,:) = [];
PDV(1,:) = [];

for AllocID = 1:N
    Packet_Delay(AllocID) = Packet_Delay(AllocID)/Arrivals(AllocID);
    Packet_Loss(AllocID) = Packet_Loss(AllocID)/Arrivals(AllocID); %Conversion to packet loss ratio
    PDV(1, AllocID) = PDV(1, AllocID)/PDV(2, AllocID);
end

PDV(2, :) = [];
Goodput = Total_Data/Time;
Load_Fairness = Load_Fairness(1)/Load_Fairness(2);
Delay_Fairness = Jain_Index(Packet_Delay);	

end
