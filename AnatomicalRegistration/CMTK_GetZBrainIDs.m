function [RegisteredPoints, PtsInRefVol, NonZeroAnatID, PtsInRefVolwAnatID] = CMTK_GetZBrainIDs(TxtFileName,FullMaskDB,Scale)
% function [RegisteredPoints, PtsInRefVol, NonZeroAnatID, PtsInRefVolwAnatID] = CMTK_GetZBrainIDs(TxtFileName,FullMaskDB,Scale)
% 6/23/2015: Gerry wrote it
% This function will take in the name (or fullpath) of a text file
% containing registered centroids from segments or voxels (TxtFileName) and
% the associated matrix of anatomical masks from the reference brain
% (FullMaskDB) in xyza, where a is the anatomical region number, with an
% associated voxel scaling factor (Scale). It will output the matrix of all
% registered centroids, as extracted from the text file (RegisteredPoints; 
% size is n by 3), as well as a logical array of size(RegisteredPoints,1)
% telling you which points were in or outside of the anatomical reference
% (PtsInRefVol), and having non-zero anatomical IDs (NonZerosAnatID)
% Finally, an array of the centroid points that were in the
% reference volume is outputted, along with the associated anatomical ID
% (PtsInRefVolwAnatID) in the 4th column and the index to the original
% points/voxels in the 5th column
%
% Input text file should be that exported from streamxform of CMTK
% FullMaskDB is a logical array
% Note that you'll need enough memory to hold all of FullMaskDB

% load in transformed centroids
fID3 = fopen(TxtFileName,'r');
xformedpoints = textscan(fID3,'%f64 %f64 %f64');
xformedpoints = cell2mat(xformedpoints);
xformedpointsori = xformedpoints;
fclose(fID3);

% scale back to pixels from microns
xformedpoints = bsxfun(@rdivide,xformedpoints,Scale);

% associate an anatomical ID, if available --> fast method, but uses lots
% of memory (can prob make it more memory efficient...)
xformedpoints(:,4) = 0; % initialize 4th column for anatomical ID
xformedpoints(:,5) = 1; % initialize 5th colume to flag points outside of volume
xformedpoints(:,6) = 1:size(xformedpoints,1); % initialize 5th column to store voxel index

% flag points outside of the volume
Counter = 0;
prevstr = [];
fprintf(1,'\n');
for b=1:size(xformedpoints,1)
    CurrPoints = round(xformedpoints(b,1:3));
    try
        CurrID = FullMaskDB(CurrPoints(1),CurrPoints(2),CurrPoints(3),1); % note that xformedpoints is in x y z, but we need to change this to y x z for matlab
    catch
        % keep track of points outside of volume just for the first anatomical ID (to prevent repeated information)
        xformedpoints(b,5) = 0;
        Counter = Counter + 1;
        str = ['Points likely outside of reference volume: ' num2str(Counter)];
        refreshdisp(str,prevstr,Counter);
        prevstr = str;
    end
end
fprintf(1,'\n');

% use linear indexing to find points in the volume and associated anatomical ID
CurrPoints = round(xformedpoints(logical(xformedpoints(:,5)),:)); % take only those points in the volume
CurrPointsIdx = sub2ind([size(FullMaskDB,1) size(FullMaskDB,2) size(FullMaskDB,3)],CurrPoints(:,1),CurrPoints(:,2),CurrPoints(:,3));
for c=1:size(FullMaskDB,4)
    CurrMaskSlice = FullMaskDB(:,:,:,c);
    CurrID = CurrMaskSlice(CurrPointsIdx);
    CurrPoints(logical(CurrID),4) = c;
end

% scale the points back to original um space
CurrPoints(:,1:3) = bsxfun(@times,CurrPoints(:,1:3),Scale);

RegisteredPoints = xformedpointsori;
PtsInRefVol = logical(xformedpoints(:,5));
NonZeroAnatID = CurrPoints(:,4)>0;
PtsInRefVolwAnatID = CurrPoints(CurrPoints(:,4)>0,1:4);
PtsInRefVolwAnatID(:,5) = CurrPoints(CurrPoints(:,4)>0,6);
% save('RegisteredAnatIDPoints','RegisteredPoints','PtsInRefVol','PtsInRefVolwAnatID');
end