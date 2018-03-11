% Fix710Tile.m
% 05/17/2010: Gerry wrote it
% 05/24/2010: tiffread28 (called by LSMto4DMatrix) has issues with super
% huge stacks; code was therefore modified to directly read in tif files
% that were previously exported from Imaris
%
% This script will fix an issue with the output of Multi-time z-stack
% tiling from the CORE710 microscope.  Specifically, it reverses the order
% of the rows in the image on a per slice basis (whole image requires too
% much memory) and output the image to a tiff series that can be imported
% to Imaris.
% 
% Note: you need to export your image to a tiff series using Imaris (can't
% use LSM Image Browser for images with >3 channels)
%
% Note: default output resolution with tiff via imwrite is 72dpi

clear all;
close all;

TileDim = 1024; % x/y dimensions of your tiles in pixels
numSlices = 1; % number of slices
numChannels = 5; % number of channels

% load the image
ImgName = 'Sect09';
TempImg = imread([ImgName '_C0_Z000.tif']);

for n=1:numSlices
%     Img = LSMto4DMatrix([ImgName '.lsm'],n);
    Img = zeros(size(TempImg,1),size(TempImg,2),1,numChannels);
    for p=1:numChannels
        Img(:,:,1,p) = imread([ImgName '_C' num2str(p-1) '_Z' num2str(n-1,'%0.3i') '.tif']);
    end
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
        imwrite(uint8(FixedImg(:,:,:,k)),[ImgName 'fixed_c' num2str(k-1) '_z' num2str(n-1) '.tiff'],'tiff');
    end
    fprintf(1,'.');
end