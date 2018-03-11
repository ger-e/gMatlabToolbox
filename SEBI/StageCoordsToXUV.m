% input settings file
[num InputXUVSettings raw] = xlsread('D:\Kurt\SEBI Temp\to split\New folder\XUVInputPositions29-30.xls');

% input positions file
Positions = xlsread('D:\Kurt\SEBI Temp\to split\New folder\InputPositions29-30.xls');

% tile dimensions
TileDim = 512;

% XY voxel dimensions
% XYVoxel = 352.777;
XYVoxel = 264.584;

% Z voxel dimensions
% ZVoxel = 0.5*352.777;
ZVoxel = 0.5*264.584;

% percent overlap of tiles
POverlap = 0.1;
POverlap = 1-POverlap;

% first calculate tile locations-------------------------------------------
NumTiles = sum(prod(Positions(:,6:7),2)); % get total number of tiles
TileCoords = zeros(45,3); % initialize matrix to put xyz coords for each tile in
offset = 0; % initialize offset
for b=1:size(Positions,1)
    CurrNumTiles = prod(Positions(b,6:7));
    TileCoords(1+offset:CurrNumTiles+offset,3) = Positions(b,4).*ZVoxel; % just take ZLast column
    
    % get xy tile locations
    Tiles = zeros(Positions(b,6),Positions(b,7),2);
    CenterTileX = ceil(Positions(b,6)/2); % assuming odd number of tiles
    CenterTileY = ceil(Positions(b,7)/2); % assuming odd number of tiles
    Tiles(CenterTileX,CenterTileY,1) = Positions(b,2); % center tile x position
    Tiles(CenterTileX,CenterTileY,2) = Positions(b,3); % center tile y position
    counter = 1 + offset;
    for d=1:Positions(b,6)
        for e=1:Positions(b,7)
            TileCoords(counter,1) = (d - CenterTileX)*POverlap*TileDim*XYVoxel; % x coord
            TileCoords(counter,2) = (e - CenterTileY)*POverlap*TileDim*XYVoxel; % y coord
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

xlswrite('outputpositions.xls',InputXUVSettings)


% 
% for d=1:Positions(b,6)
%     for e=1:Positions(b,7)
%         Tiles(d,e,1) = (d - CenterTileX)*512*0.44;
%         Tiles(d,e,2) = (e - CenterTileY)*512*0.44;
%     end
% end