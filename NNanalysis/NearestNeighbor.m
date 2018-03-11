function [NNdist meanNNdist sdNNdist modeNNdist]  = NearestNeighbor(Spots)
% NearestNeighbor.m
% 05/26/2010: Gerry wrote it
% 06/14/2010: Added proper scaling factor for distances-->microns per pixel
% 07/28/2010: Removed scaling factor-->NOT NEEDED; imaris already does this
% for you when you export
%
% This script will calculate the nearest neighbor distances between a set
% of points in three-dimensional space
%
% Dependencies: need d2points3d.m

% calculate the distance between each point and every other point
distances = zeros(size(Spots,1),size(Spots,1));
for a=1:size(Spots,1)
    for b=1:size(Spots,1)
        distances(a,b) = d2points3d(Spots(a,1),Spots(a,2),Spots(a,3),Spots(b,1),Spots(b,2),Spots(b,3));
    end
end

% now find the nearest neighbor distances
distances2 = distances;
distances2(distances2 == 0) = 1000000; % fudge to get rid of zeros along diagonal
for c=1:length(distances2)
    distances2(distances2(:,c) ~= min(distances2(:,c)),c) = 0;
end

% eliminate matrix symmetry
for d=1:length(distances2)
    distances2(d,1:d) = 0;
end

% get the stats about nearest neighbor distance
NNdist = sum(distances2,1); %.*MicronsPerPix; % scaling factor for distances
NNdist = NNdist(NNdist>0); % get rid of 0's
meanNNdist = mean(NNdist);
sdNNdist = std(NNdist);
modeNNdist = mode(NNdist);
% hist(NNdist)
