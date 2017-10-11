function [ out ] = RNG( F )
% RNG Random Number Generator
%  Generates a random number from the probability distribution F. Input F must be already sorted
%
%  See also EVENT7, EXTRACT_DISTRIBUTION, FORM_TRAFFIC.

p = rand;
for i = 1:length(F)
   sum = 0;
   for k = 1:i
      sum = sum + F(2,k);
   end
   if p <= sum
      out = F(1,i);
      break;
   end
end

end