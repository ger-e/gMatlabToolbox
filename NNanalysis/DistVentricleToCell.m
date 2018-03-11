% DistVentricleToCell.m
% 12/07/2011: Gerry wrote it
% 06/19/2014: Updated to use pdist
% This script will take two inputs: a spreadsheet of exported Imaris spots
% and a single-plane image, whereby some landmark of interest is annotated
% in the blue channel (at max 8-bit, i.e. 255 intensity). For instance,
% location of newborn cortical neurons could be your spots, and the
% ventricular surface (just a spline/line) could be your landmark. The
% script will output the minimum distance between each spot and the
% landmark of interest, on a per spot basis.

% The easiest way to delineate a landmark of interest is to use the spline
% (curve) drawing tool in LSM image browser, using color blue (255). Then
% just export the image (with no channels on!) as 'Full resolution of image
% window - single plane'.

% stuff to edit------------------------------------------------------------

% path to your images
rootDir = 'C:\Users\Gerry\Desktop';

% file name of image w/ ventricle delineated
% note: tif only!
imgname = 'Ce1.tif';

% file name of excel spreadsheet with spots
spotsname = 'Ce1.xls';

% voxel size (xy) in microns
voxelSize = 0.33;

% -------------------------------------------------------------------------
fprintf(1,'\nCalculating...');

% load the image
img = imread([rootDir '\' imgname]);

% only keep blue channel
img = img(:,:,3);

% find the segmented ventricle location
indx = find(img==255);

% convert to coordinates; note that we reverse them so that we use the same
% origin Imaris uses
[Coords(:,2) Coords(:,1)] = ind2sub(size(img),indx);

% scale based upon voxel size
ScaledCoords = Coords.*voxelSize;

% now load the spreadsheet of spots
CellCoords = xlsread([rootDir '\' spotsname],'Position');
CellCoords = CellCoords(:,1:2); % discard Z information

% now find the shortest distance between each cell and the ventricle
% surface
MinCellDistances = pdist2(ScaledCoords,CellCoords,'euclidean','Smallest',1);

% output to excelspreadsheet
xlswrite([imgname(1:end-4) '_MinCellDists'],MinCellDistances');

fprintf(1,'Done!\n');