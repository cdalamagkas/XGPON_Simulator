function [out] = PHY_Payload(XGTC_Payloads)
% PHY_PAYLOAD Apply RS(248,232) code on XGTC frame
%  Applies Reed-Solomon FEC code to one or more XGTC frames, after adding 
%  XGTC overhead. Returns the final size of PHY payload which includes 
%  XGTC overhead + XGTC_Payload + FEC overhead. 
%
%  See also DBA.
   N = length(XGTC_Payloads);
   out = zeros(1, N);
	XGTC_Frame = zeros(1, N);
   for i=1:N
      XGTC_Frame(i)  = XGTC_Payloads(i) + 8;
      out(i) = ceil(XGTC_Frame(i)/232)*16 + XGTC_Frame(i); 
   end
end