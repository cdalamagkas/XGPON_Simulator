function [ PDT ] = Set_PDT( N )
% SET_PDT Sets the PDT of ONU's network
%  Sets the distance of each ONU from the OLT and calculates the
%  corresponding propagation delay time (PDT). ONUs are placed
%  uniformly in range [20,60] km
%
%  See also XGPON.

PDT = zeros(1,N);
SpeedLight = 299792458*0.7;
for i=1:N
    ONU_Placement = rand*(60000-20000)+20000; % in meters
    PDT(i) = ONU_Placement/SpeedLight;
end

end