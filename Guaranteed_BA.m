function [Guaranteed_Allocations, Demands] = Guaranteed_BA(Demands, D, N )
% GUARANTEED_BA Allocates guaranteed bandwidth to AllocIDs
%  Allocates R_F statically and R_A dynamically to AllocIDs. 
%
%  See also DBA, EVENT1.

Guaranteed_Allocations = zeros(1,N);

%% Allocate R_F regadless of ONUs needs
for AllocID = 1:N
    Guaranteed_Allocations(AllocID) = D(1);
    Demands(AllocID) = Demands(AllocID) - D(1);
    if Demands(AllocID) < 0
        Demands(AllocID) = 0;
    end
end

%% Allocate R_A dynamically
if nnz(Demands) > 0 %if at least one node wants additive bandwidth
    for AllocID = 1:N
      if Demands(AllocID) > 0 && Demands(AllocID) <= D(2) 
         Guaranteed_Allocations(AllocID) = Guaranteed_Allocations(AllocID) + Demands(AllocID);
         Demands(AllocID) = 0;
      elseif Demands(AllocID) > D(2)
         Guaranteed_Allocations(AllocID) = Guaranteed_Allocations(AllocID) + D(2);
         Demands(AllocID) = Demands(AllocID) - D(2);
      end
   end
end

end
