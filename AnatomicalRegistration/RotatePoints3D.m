function RotatedPoints = RotatePoints3D(MyPoints,ScaleXYZ,AngleXYZ)
% function RotatedPoints = RotatePoints3D(MyPoints,ScaleXYZ,AngleXYZ)
% 6/19/2015: Gerry wrote it
% This function will apply a matrix transformation-based rotation to a n by
% 3 matrix (MyPoints) of points (points in x,y,z order). Coordinate
% magnitudes are scaled by specified voxel size (ScaleXYZ) and the rotation
% (in radians) is performed around each axis as specified (AngleXYZ).

% first rescale the points according to voxel dimensions
MyPoints(:,1) = MyPoints(:,1).*ScaleXYZ(1); % scale x
MyPoints(:,2) = MyPoints(:,2).*ScaleXYZ(2); % scale y
MyPoints(:,3) = MyPoints(:,3).*ScaleXYZ(3); % scale z

% specify center of rotation; note that we need both the width of the point
% cloud (max-min) but also the displacement of the cloud from the origin
% (min)
OriCenter = [(max(MyPoints(:,1))-min(MyPoints(:,1)))./2+min(MyPoints(:,1)) (max(MyPoints(:,2))-min(MyPoints(:,2)))./2+min(MyPoints(:,2)) max((MyPoints(:,3))-min(MyPoints(:,3)))./2];

% translate point cloud to center of rotation
MyPoints = bsxfun(@minus,MyPoints,OriCenter);

alpha = AngleXYZ(1);
beta = AngleXYZ(2);
% gamma = -pi/2; % 90deg
gamma = AngleXYZ(3); % 180deg

% specify transformation matrix
rotx = [1 0 0; 0 cos(alpha) -sin(alpha); 0 sin(alpha) cos(alpha)];
roty = [cos(beta) 0 sin(beta); 0 1 0; -sin(beta) 0 cos(beta)];
rotz = [cos(gamma) -sin(gamma) 0; sin(gamma) cos(gamma) 0; 0 0 1];

% do the rotation
MyPoints = MyPoints*rotx*roty*rotz;

% now move back to original center
RotatedPoints = bsxfun(@plus,MyPoints,OriCenter);

end