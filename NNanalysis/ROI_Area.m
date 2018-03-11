% area for density measurements / getting ROI via convex hull
% xy (i.e. 2D) only for now
% 5/10/11: Gerry wrote it

InputPoints = []; % copy and paste your input points from Imaris spreadsheet

% get xy coords
x = InputPoints(:,1);
y = InputPoints(:,2);

% get convex hull
k = convhull(x,y);

% get area
Area = polyarea(x(k),y(k))

% plot result
plot(x(k),y(k),'r-',x,y,'b+');

% get density in mm^2
Density = length(x)/(Area/1000000)