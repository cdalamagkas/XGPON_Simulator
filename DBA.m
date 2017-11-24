function [ BWmap, CAT, BufOcc_Buffer, Load_Fairness ] = DBA ( Time, BufOcc_Buffer, BWmap, D, CAT, Downstream_Transmission_Delay, Guard_Time, C, N, Upstream_Speed, PDT, Load_Fairness, PAS_Flag )
% DBA The Dynamic Bandwidth Allocation mechanism of XG-PON  
%  DBA is called by Event1 every 125 usec and creates BWmap of the
%  upcomming downstream frame. Performs bandwidth allocation and
%  transmission scheduling for the upstream channel based on the 
%  received DBRus.
% 
%   See also EVENT1, GUARANTEED_BANDWIDTH_ALLOCATION, REED_SOLOMON.

Initial_Demands = BufOcc_Buffer;
BufOcc_Buffer = zeros(1,N);
Demands(:) = Initial_Demands(:) + 4;
%fprintf('Bandwidth Allocation starts\n\tDemand: '); disp(Demands);	

%% Guaranteed bandwidth allocation and calculation of exessive demands

[Guaranteed_Allocations, Non_Guaranteed_Demands] = Guaranteed_BA(Demands, D, N);
%fprintf('\tGuaranteed allocations: '); disp(Guaranteed_Allocations);
Final_Allocations = zeros(1,N);
Residual_Bandwidth = C;
for AllocID = 1:N
    if Non_Guaranteed_Demands(AllocID) == 0
        Residual_Bandwidth = Residual_Bandwidth - PHY_Payload(Guaranteed_Allocations(AllocID));
        Final_Allocations(AllocID) = Guaranteed_Allocations(AllocID);
    end
end

%% Non-Guaranteed bandwidth allocation phase
if PAS_Flag && nnz(Non_Guaranteed_Demands) > 1 && sum(PHY_Payload(Non_Guaranteed_Demands)) > Residual_Bandwidth
   %% allocate non-guaranteed BW using the market equilibrium
    s = zeros(2,0);
    for AllocID = 1:N
        if Non_Guaranteed_Demands(AllocID) > 0 
            s(1, end+1) = PHY_Payload(Non_Guaranteed_Demands(AllocID) + Guaranteed_Allocations(AllocID));
            s(2, end) = AllocID;
        end
    end
    a = zeros(1,length(s));
    for i = 1:length(s)
        a(i) = floor( s(1,i) * Residual_Bandwidth / sum(s(1,:)) ); % allocate using the equilibrium
        Final_Allocations(s(2,i)) = a(i) - ceil(a(i)/232)*16 - 8; % assign the clean amount of bytes
    end
elseif C - sum(PHY_Payload(Guaranteed_Allocations)) > 0 && nnz(Non_Guaranteed_Demands) > 0
   %% allocate non-guaranteed BW 'blindly'
   Final_Allocations = Guaranteed_Allocations;
   Flag = true;
   while Flag && sum(Non_Guaranteed_Demands) > 0 && C > sum(PHY_Payload(Final_Allocations))
      Minimum_Demand = Inf;
      for AllocID = 1:N
         if Non_Guaranteed_Demands(AllocID) < Minimum_Demand && Non_Guaranteed_Demands(AllocID) > 0
            Minimum_Demand = Non_Guaranteed_Demands(AllocID);
         end
      end
      for AllocID = 1:N
         if Non_Guaranteed_Demands(AllocID) > 0
            Test_Allocation = Final_Allocations;
            Test_Allocation(AllocID) = Test_Allocation(AllocID) + Minimum_Demand;
            if C - sum(PHY_Payload(Test_Allocation)) >= 0
               Non_Guaranteed_Demands(AllocID) = Non_Guaranteed_Demands(AllocID) - Minimum_Demand;
               Final_Allocations(AllocID) = Final_Allocations(AllocID) + Minimum_Demand;
            else
               Test_Allocation = Final_Allocations;
               Test_Allocation(AllocID) = [];
               Residual_Bandwidth = C - sum(PHY_Payload(Test_Allocation));
               Final_Allocations(AllocID) = Residual_Bandwidth - ceil(Residual_Bandwidth/232)*16 - 8;
               Flag = false;
               break;
            end
         end
      end
   end
end

%% Schedule allocations
for AllocID = 1 : N
    Allocated_Size = PHY_Payload(Final_Allocations(AllocID));
    Arrival_Time = Time + PDT(AllocID) + Downstream_Transmission_Delay + Allocated_Size/Upstream_Speed + PDT(AllocID);
    if Arrival_Time > CAT && Arrival_Time - CAT >= Guard_Time
        StartTime = 0;
        CAT = Arrival_Time;
    elseif Arrival_Time > CAT && Arrival_Time - CAT < Guard_Time
        StartTime = CAT - Arrival_Time + Guard_Time;
        CAT = Arrival_Time + StartTime; 
    else
        StartTime = CAT - Arrival_Time;
        CAT = CAT + Guard_Time;
    end
    BWmap(2, AllocID) = AllocID;
    BWmap(2, AllocID) = StartTime;
    BWmap(3, AllocID) = Final_Allocations(AllocID);
end
%fprintf('\tFinal allocations: '); disp(BWmap(3,:));
%% Calculate Fairness Index of allocations
Demand = zeros(1,0);
Supply = zeros(1,0);

for i = 1 : N
    if Initial_Demands(i) > 0
        Demand(end+1) = Initial_Demands(i);
        Supply(end+1) = BWmap(3, i);
    end
end

if ~isempty(Demand)
    Load_Fairness(1) = Load_Fairness(1) + Jain_Index(Supply./Demand);
    Load_Fairness(2) = Load_Fairness(2) + 1;
end

end