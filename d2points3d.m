function distance = d2points3d(x1,y1,z1,x2,y2,z2)
% function distance = d2points3d(x1,y1,z1,x2,y2,z2)
% calculates the distances between two points in three dimensions in
% cartesian space

distance = ((x1-x2)^2+(y1-y2)^2+(z1-z2)^2)^0.5;