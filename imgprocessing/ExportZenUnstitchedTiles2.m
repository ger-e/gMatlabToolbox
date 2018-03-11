% ExportZenUnstitchedTiles.m
% 02/21/2011: Gerry wrote it
% 08/31/2011: Gerry updated it to directly write to an Imaris file
% 05/09/2012: Gerry modifed it to directly use tiffread function, as
% opposed to performing time-consuming and memory-intensive step of
% converting to a 4D matrix via LSMto4DMatrix. 'Tiles' variable is now also
% cleared before Imaris conversion to prevent memory bottlenecks
% 07/31/2014: Gerry modified to be able to process single channel images
% (where the Tile struct is slightly different)
%
% Note: currently written to work with whatever input constraints are in
% the tiffreader (tiffread28 e.g.)
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
% 2) imwrite cannot output 12-bit tiffs

% full path to directories
InputDir = 'E:\Gerry\ZenTileExport\input'; % script will perform operation on all *.lsm files in input dir
OutputDir = 'E:\Gerry\ZenTileExport\output'; % script will export tiles to a folder for each lsm file read from input dir

cd(InputDir);
ImgList = dir('*.lsm'); % get list of images to process

% open COM access to Imaris
vImarisApplication=actxserver('Imaris.Application');

for d=1:size(ImgList,1)
    CurrentImg = ImgList(d).name;
    TileInfo = lsminfo(CurrentImg); % get xyz dimensions of each tile
    Tiles = tiffread30(CurrentImg); % read in the image (as one giant stack)
    NumTiles = size(Tiles,2)/TileInfo.DimensionZ; % number of slices in giant stack divided by the number of slices per tile

    cd(OutputDir);
    mkdir(CurrentImg); % store output images in individual directories
    cd(CurrentImg);
    
    % now get the tiles and export to tiff series
    if iscell(Tiles(1,1).data) % for multi-channel
        for a=1:NumTiles
            for b=1:TileInfo.DimensionZ % slice
                for c=1:size(Tiles(1,1).data,2) % channel
                    imwrite(Tiles(1,b+TileInfo.DimensionZ*(a-1)).data{c},[ImgList(d).name '_t' num2str(a) '_z' num2str(b) '_c' num2str(c) '.tiff'],'tif','Compression','none','Resolution',[96 96]);
                end
            end
        end
    else % for single channel
        for a=1:NumTiles
            for b=1:TileInfo.DimensionZ
                imwrite(Tiles(1,b+TileInfo.DimensionZ*(a-1)).data,[ImgList(d).name '_t' num2str(a) '_z' num2str(b) '.tiff'],'tif','Compression','none','Resolution',[96 96]);
            end
        end
    end
    
    % free up memory before loading stuff into imaris
    clear Tiles;
    
    % load the tiff series into imaris and export as tile stack time series
    currDir = pwd; % get the current directory
    
    if iscell(Tiles(1,1).data)
        vImarisApplication.FileOpen([currDir '\' ImgList(d).name '_t1_z1_c1.tiff']);
    else
        vImarisApplication.FileOpen([currDir '\' ImgList(d).name '_t1_z1.tiff']);
    end
    vImarisApplication.FileSave([currDir '\' ImgList(d).name '_tiles.ims']);    
    
    
    cd(InputDir);
    fprintf('.');
end