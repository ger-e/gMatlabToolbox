% EstCoordsToXUV.m
% 4/2011: Gerry wrote it
% 5/2011: Gerry fixed many bugs
%           a) changed to now take center of the Z stack
%           b) center tile xy position is now read from the stage
%           coordinates (defaulted to (0,0) previously)
% 6/2011: Gerry changed from StageCoordsToXUV to EstCoordsToXUV to reflect
% the fact that we will now take single overlapping tiles between slabs,
% align them in XUV, then import their aligned coordinates and generate
% appropriate coordinates of all other tiles in the slab. Gerry also added
% in the ability to export concatenated XUVOutputSettings for easier import
% into XUV.
%
% For use with SEBI: Serial End-Block Imaging
% 
% This script will take an input excel spreadsheet with the following
% information in each column: (1) slab number, (2) xcoord of reference
% tile, (3) ycoord of reference tile, (4) zcoord of reference tile, (5)
% number of tiles in x, (6) number of tiles in y, (7) reference tile index
% (matlab indexing). The reference tile is the of a given slab used to
% create a xuv alignment between all slabs in the SEBI reconstruction.
%
% The script will use the input information to generate a set of tile
% coordinates for an entire slab of tiles, across multiple slabs. These
% coordinates will then be exported to an excel spreadsheet, whose contents
% can be directly copied and pasted into XUVStich as coordinates for
% stitching.

% input XUV settings file (important for getting the right number of tiles)
[num InputXUVSettings raw] = xlsread('J:\sebi temp\082412-05 56 dpi stim ChR\Alignment\XUVinputpositions.xls');

% input positions file
% column order: slab, x, y, z, tileX, tileY, reference tile
Positions = xlsread('J:\sebi temp\082412-05 56 dpi stim ChR\Alignment\inputpositions.xls');

% tile dimensions
TileDim = 512;

% XY voxel dimensions
XYVoxel = 264.584;
% XYVoxel = 1;

% Z voxel dimensions
ZVoxel = 1;

% percent overlap of tiles
POverlap = 0.1;
POverlap = 1-POverlap;

% first calculate tile locations-------------------------------------------
NumTiles = sum(prod(Positions(:,5:6),2)); % get total number of tiles
TileCoords = zeros(NumTiles,3); % initialize matrix to put xyz coords for each tile in
offset = 0; % initialize offset

for b=1:size(Positions,1)
    CurrNumTiles = prod(Positions(b,5:6));
   
    % get z-coord for this slab's tiles
    TileCoords(1+offset:CurrNumTiles+offset,3) = Positions(b,4).*ZVoxel;
    
    % get xy tile locations
    Tiles = zeros(Positions(b,6),Positions(b,5),2);
    [RefTileYCoord RefTileXCoord] = ind2sub([Positions(b,6) Positions(b,5)],Positions(b,7)); % reference tile coordinates; note that xy coords reversed in matlab
    RefTileYPos = Positions(b,3); % y position of reference tile
    RefTileXPos = Positions(b,2); % x position of reference tile
    counter = 1 + offset;
    for d=1:Positions(b,5) % x direction
        for e=1:Positions(b,6) % y direction
            if (RefTileXCoord - d) == 0
                TileCoords(counter,1) = RefTileXPos; % if at ref tile coord, put in ref tile position
            else
                TileCoords(counter,1) = RefTileXPos - (RefTileXCoord - d)*POverlap*TileDim*XYVoxel; % otherwise put in appropriate x position
            end
            if (RefTileYCoord - e) == 0
                TileCoords(counter,2) = RefTileYPos;
            else
                TileCoords(counter,2) = RefTileYPos - (RefTileYCoord - e)*POverlap*TileDim*XYVoxel; % y position
            end
            counter = counter + 1;
        end
    end
    offset = offset + CurrNumTiles; % offset for putting in next stack's tile coordinates
end

% then output the actual locations-----------------------------------------
% go through each set of position parameters for each tile; jump by 3's
% because you want only the position parameter
counter = 1;
for a=1:3:size(InputXUVSettings,1)-2
    InputXUVSettings(a,3) = {[num2str(TileCoords(counter,3)) ',' num2str(TileCoords(counter,2)) ',' num2str(TileCoords(counter,1))]}; % tile####_abs_pos_um, Z Y X
    counter = counter+1;
end

% in case excel is stupid and doesn't think '1' is a string
for b=3:3:size(InputXUVSettings,1)
    InputXUVSettings(b,3) = {num2str(1)};
end

% concatenate for import to XUV
for c=1:size(InputXUVSettings,1)
    InputXUVSettingsConcatenated{c} = [InputXUVSettings{c,1} InputXUVSettings{c,2} InputXUVSettings{c,3}];
end
InputXUVSettingsConcatenated = InputXUVSettingsConcatenated';

% now write to excel spreadsheet
xlswrite('XUVOutputSettings.xls',InputXUVSettingsConcatenated);