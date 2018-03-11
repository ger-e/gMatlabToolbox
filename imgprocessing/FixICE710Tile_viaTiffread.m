% Fix710Tile.m
% 05/17/2010: Gerry wrote it
%
% This script will fix an issue with the output of z-stack
% tiling from the ICE710 microscope.  
%
% note that default output with tiff via imwrite is 72dpi

clear all;
close all;

TileDim = 1024; % x/y dimensions of your tiles in pixels
numSlices = 8; % number of slices
numChannels = 3; % number of channels
xDim = 2; % number of tiles in x direction
yDim = 2; % number of tiles in y direction

% load the image
ImgName = 'mRIEWC-ReporterCHEY-3weeks-C-2';
Img = LSMto4DMatrix([ImgName '.lsm']);

% initialize
FixedImg = zeros(yDim,xDim,numSlices,numChannels);

% now repair the image
numTiles = xDim*yDim;
for d=1:numChannels
    for b=1:yDim
        for c=1:xDim
            for a=1:numSlices
                FixedImg(1+(b-1)*1024:b*1024,1+(c-1)*1024:c*1024,a,d) = Img(:,:,(b-1)*numSlices*2+(c-1)*numSlices+a,d);
            end
        end
    end
end

% export the new image to 72dpi tiff
for n=1:size(FixedImg,3)
    for k=1:size(FixedImg,4)
        imwrite(uint16(FixedImg(:,:,n,k)),[ImgName '_c' num2str(k) '_z' num2str(n) '.tiff'],'tiff');
    end
end
fprintf(1,'.');