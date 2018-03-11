function [x y] = icdf_gerry(Distribution)
% function [x y] = icdf_gerry(Distribution)
% 03/24/2011: Gerry wrote it
% This function will export the xy coordinates of the inverse cumulative
% distribution function, i.e. instead of reporting the frequency of point x
% as F(x), it will report 1-F(x). Layman interpretation: each point on the
% resulting cdfplot will report the confidence level (as opposed to the
% probability of occurance). To then plot the icdf, simply do plot(x,y) or
% line(x,y).

SortedDistribution = sort(Distribution); % sort the distribution
y = zeros(length(SortedDistribution),1); % preallocate

% figure out the y coords for export
for i=1:length(SortedDistribution)
    y(i) = (length(SortedDistribution)-i)/length(SortedDistribution);
end
x = SortedDistribution;