function distance = d2points(x1,y1,x2,y2)
%function distance = d2points(x1,y1,x2,y2)
%calculates distance between two points given in cartesian coordinates

distance = ((x2-x1)^2 + (y2-y1)^2)^0.5;
