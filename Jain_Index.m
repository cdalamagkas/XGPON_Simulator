function [ J ] = Jain_Index(V)
% JAIN_INDEX Jain index of vector
%  Calculates the jain fairness index of an input vector
%
%  See also DBA, EVENT4

   J = sum(V)^2/(length(V)*sum(V.^2));
end