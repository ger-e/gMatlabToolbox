% ExportZenUnstitchedTiles.m
% 02/21/2011: Gerry wrote it
% 08/31/2011: Gerry updated it to directly write to an Imaris file
%
% Note: currently written to work with uint8 images only
%
% This script will read in a lsm file outputted by Zen that has the
% following properties: (1) a tiled image with >0% overlap and (2) the
% image was not stitched together using the stitch function in Zen, and is
% therefore unreadable as a tiled image in any program other than Zen. This
% script will export the individual tiles for manual stitching or stitching
% using XuvStitch.
%
% Notes
% 1) In Windows, it seems like you can't have a filename more than 87 char long
% 2) imwrite cannot output 12-bit tiffs, so they will automatically be
% converted to 16-bit

% full path to directories
InputDir = 'X:\Gerry\testZenTileExport\input'; % script will perform operation on all *.lsm files in input dir
OutputDir = 'X:\Gerry\testZenTileExport\output'; % script will export tiles to a folder for each lsm file read from input dir

cd(InputDir);
ImgList = dir('*.lsm'); % get list of images to process

% open COM access to Imaris
vImarisApplication=actxserver('Imaris.Application');

for d=1:size(ImgList,1)
    CurrentImg = ImgList(d).name;
    TileInfo = lsminfo(CurrentImg); % get xyz dimensions of each tile
    Tiles = LSMto4DMatrix(CurrentImg); % read in the image (as one giant stack)
        % temp hack
        Tiles = uint8(Tiles);
%     if max(Tiles(:))>255 && max(Tiles(:))<5000 % convert 12-bit to 16-bit
%         Tiles = uint16(Tiles);
%     end
    NumTiles = size(Tiles,3)/TileInfo.DimensionZ; % number of slices in giant stack divided by the number of slices per tile

    cd(OutputDir);
    mkdir(CurrentImg); % store output images in individual directories
    cd(CurrentImg);
    
    % now get the tiles and export to tiff series
    for a=1:NumTiles
%         mkdir(['t' num2str(a)]); % store tiles in individual directories
%         cd(['t' num2str(a)]);
        for b=1:TileInfo.DimensionZ % slice
            for c=1:size(Tiles,4) % channel
                imwrite(Tiles(:,:,b+TileInfo.DimensionZ*(a-1),c),[ImgList(d).name '_t' num2str(a) '_z' num2str(b) '_c' num2str(c) '.tiff'],'tif','Compression','none','Resolution',[96 96]);
            end
        end
%         cd ..
    end
    
    % load the tiff series into imaris and export as tile stack time series
    currDir = pwd; % get the current directory
    vImarisApplication.FileOpen([currDir '\' ImgList(d).name '_t1_z1_c1.tiff']);
    vImarisApplication.FileSave([currDir '\' ImgList(d).name '_tiles.ims']);    
    
    clear Tiles;
    cd(InputDir);
    fprintf('.');
end