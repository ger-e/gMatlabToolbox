% Fix710Tile.m
% 05/17/2010: Gerry wrote it
%
% This script will fix an issue with the output of Multi-time z-stack
% tiling from the CORE710 microscope.  Specifically, it reverses the order
% of the rows in the image on a per slice basis (whole image requires too
% much memory) and output the image to a tiff series that can be imported
% to Imaris.
%
% note that default output with tiff via imwrite is 72dpi

clear all;
close all;

TileDim = 1024; % x/y dimensions of your tiles in pixels
numSlices = 43; % number of slices

% load the image
ImgName = 'Tile_dapi-gfp_Sum_first';

for n=1:numSlices
    Img = LSMto4DMatrix([ImgName '.lsm'],n);

    NumRows = size(Img,1)/TileDim;
    RowTilesFwd = 1:NumRows;
    RowTilesRev = sort(RowTilesFwd*-1)*-1;

    FixedImg = zeros(size(Img));

    % re-order the rows of tiles
    for i=1:size(Img,4)
        for j=1:length(RowTilesFwd)
            if j==1
                FixedImg(1:RowTilesFwd(j)*TileDim,:,:,i) = Img(RowTilesRev(j+1)*TileDim+1:RowTilesRev(j)*TileDim,:,:,i);
            else
                if j==length(RowTilesFwd)
                    FixedImg(RowTilesFwd(j-1)*TileDim+1:RowTilesFwd(j)*TileDim,:,:,i) = Img(1:RowTilesRev(j)*TileDim,:,:,i);
                else
                    FixedImg(RowTilesFwd(j-1)*TileDim+1:RowTilesFwd(j)*TileDim,:,:,i) = Img(RowTilesRev(j+1)*TileDim+1:RowTilesRev(j)*TileDim,:,:,i);
                end
            end
        end
    end

    % export the new image to 72dpi tiff
    for k=1:size(FixedImg,4)
        imwrite(uint8(FixedImg(:,:,:,k)),[ImgName '_c' num2str(k) '_z' num2str(n) '.tiff'],'tiff');
    end
    fprintf(1,'.');
end