% MigrationVectorField.m
% 12/2010: Gerry wrote it
%
% This script will read in a spreadsheet from Imaris which was exported
% from measurement points where pairs of points represent the direction of
% a cell's migration. The script will then plot in 3D the unit vectors or tensors
% based upon the input data.

InputFile = 'K:\1-DGTangentialCut\Migration\MigrationVectorField\SetFull10RH_Dapi-GM130-Dcx_ICE710_Sect06_pruned.xls'; % full path to file
InputMatrix = xlsread(InputFile,'Position');
InputMatrix = InputMatrix(:,1:3); % just take the XYZ coords
starts = InputMatrix(1:2:end,:); % get the start points
ends = InputMatrix(2:2:end,:); % get the end points

% calculate the unit vectors (so you don't have to worry about different
% magnitudes of the vectors you drew in imaris
unitVector = zeros(size(ends));
for a=1:size(ends,1)
    unitVector(a,1) = (ends(a,1)-starts(a,1))./d2points3d(starts(a,1),starts(a,2),starts(a,3),ends(a,1),ends(a,2),ends(a,3));
    unitVector(a,2) = (ends(a,2)-starts(a,2))./d2points3d(starts(a,1),starts(a,2),starts(a,3),ends(a,1),ends(a,2),ends(a,3));
    unitVector(a,3) = (ends(a,3)-starts(a,3))./d2points3d(starts(a,1),starts(a,2),starts(a,3),ends(a,1),ends(a,2),ends(a,3));
end

% then plot the vector field
figure;
quiver3(starts(:,1),starts(:,2),starts(:,3),unitVector(:,1),unitVector(:,2),unitVector(:,3));
axis square;
axis equal;