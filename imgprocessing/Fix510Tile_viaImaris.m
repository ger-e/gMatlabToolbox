function Fix510Tile_viaImaris()
% 06/04/2010: Gerry wrote it from Fix710Tile_viaImaris.m
%
% This script will fix an issue with the output of Multi-time z-stack
% tiling from the CORE510 microscope.  Specifically, it addresses an issue
% where the edges of tiles were repeated in neighboring tiles.
% 
% Note: you need to export your image to a tiff series using Imaris (can't
% use LSM Image Browser for images with >3 channels)
%
% Note: default output resolution with tiff via imwrite is 72dpi

% image parameters
numSlices = 28; % number of slices
numChannels = 5; % number of channels
ImgName = 'Sect07'; % image must have been exported previously as *.tif via Imaris

% tile parameters
TileDim = 512; % tile square size in pixels
Xcomp = 18; % for each row
Ycomp = 3; % for each row
XcompC = 1; % for each column
YcompC = 11; % for each column
XTileNum = 5; % number of tiles in x direction
YTileNum = 9; % number of tiles in y direction
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------

% some calculations based upon tile parameters
TileNum = XTileNum*YTileNum; % total number of tiles
Tiles = zeros(TileDim,TileDim,TileNum); % matrix to throw your tiles in
% NOTE: the tiles in the 'Tiles' matrix will be numbered using Matlab
% matrix formatting, i.e. [1 4
%                          2 5
%                          3 6];

% load in a slice of the image
for n=1:numSlices
    for p=1:numChannels
        Img = imread([ImgName '_C' num2str(p-1) '_Z' num2str(n-1,'%0.3i') '.tif']);
        for c=1:XTileNum
            for d=1:YTileNum
                Tiles(:,:,d+YTileNum*(c-1)) = Img(1+TileDim*(d-1):TileDim*d,1+TileDim*(c-1):TileDim*c);
            end
        end
        % initialize matrix for fixed image
%         newimg = zeros(TileDim*YTileNum - (YTileNum-1)*Ycomp+YcompC, TileDim*XTileNum + (YTileNum-1)*XcompC*Xcomp - 1);
newimg = zeros(TileDim*YTileNum+500,TileDim*XTileNum+500);
        % initialize matrix for masking (used for proper overwriting at tile overlap locations
        maskimg = newimg; % dummy image
        dummyTiles = ones(TileDim,TileDim,TileNum); % just some dummy tiles

        % now get your mask (misnomer: it keeps track of how many times
        % you've overlapped tiles)
        maskimg = fixImg(dummyTiles,maskimg,XTileNum,YTileNum);

        % now fix the image
        Tiles = fixImg(Tiles,newimg,XTileNum,YTileNum);
        fixedTiles = Tiles./maskimg; % divide by mask image to prevent oversummation

        % export the new image to 72dpi tiff
        imwrite(uint8(fixedTiles),[ImgName 'fixed_c' num2str(p-1) '_z' num2str(n-1) '.tiff'],'tiff');
        
        clear Tiles;
    end
    fprintf(1,'.');
end

function fixedImg = fixImg(inputTiles,fixedImg,XTileNum,YTileNum)
    for b=1:XTileNum
        for a=1:YTileNum
            fixedImg((b-1)*YcompC+1+(TileDim-Ycomp)*(a-1):(b-1)*YcompC+(TileDim-Ycomp)*(a-1)+TileDim,1+(b-1)*TileDim-(b-1)*XcompC+(a-1)*Xcomp:(b-1)*TileDim-(b-1)*XcompC+TileDim+(a-1)*Xcomp) = inputTiles(:,:,a+YTileNum*(b-1));
%             temp = fixedImg((b-1)*YcompC+1+(TileDim-Ycomp)*(a-1):(b-1)*YcompC+(TileDim-Ycomp)*(a-1)+TileDim,1+(b-1)*TileDim-(b-1)*XcompC+(a-1)*Xcomp:(b-1)*TileDim-(b-1)*XcompC+TileDim+(a-1)*Xcomp);
%             temp = inputTiles(:,:,a+YTileNum*(b-1)) + temp;
%             fixedImg((b-1)*YcompC+1+(TileDim-Ycomp)*(a-1):(b-1)*YcompC+(TileDim-Ycomp)*(a-1)+TileDim,1+(b-1)*TileDim-(b-1)*XcompC+(a-1)*Xcomp:(b-1)*TileDim-(b-1)*XcompC+TileDim+(a-1)*Xcomp) = temp;
    %         maskimg(1+(b-1)*TileDim-(b-1)*XcompC+(a-1)*Xcomp:(b-1)*TileDim-(b-1)*XcompC+TileDim+(a-1)*Xcomp,(b-1)*YcompC+1+(TileDim-Ycomp)*(a-1):(b-1)*YcompC+(TileDim-Ycomp)*(a-1)+TileDim) = dummyTile;        

    %         maskimg(1+0*TileDim-0*XcompC+(a-1)*Xcomp:1+0*TileDim-0*XcompC+TileDim+(a-1)*Xcomp,0*YcompC+1+(TileDim-Ycomp)*(a-1):0*YcompC+(TileDim-Ycomp)*(a-1)+TileDim) = dummyTile;
    %         maskimg(1+1*TileDim-1*XcompC+(a-1)*Xcomp:1+1*TileDim-1*XcompC+TileDim+(a-1)*Xcomp,1*YcompC+1+(TileDim-Ycomp)*(a-1):1*YcompC+(TileDim-Ycomp)*(a-1)+TileDim) = dummyTile;
    %         maskimg(1+2*TileDim-2*XcompC+(a-1)*Xcomp:1+2*TileDim-2*XcompC+TileDim+(a-1)*Xcomp,2*YcompC+1+(TileDim-Ycomp)*(a-1):2*YcompC+(TileDim-Ycomp)*(a-1)+TileDim) = dummyTile;
        %     maskimg(1+0*Xcomp:TileDim+0*Xcomp,1+(TileDim-Ycomp)*0:(TileDim-Ycomp)*0+TileDim) = dummyTile;
        %     maskimg(1+1*Xcomp:TileDim+1*Xcomp,1+(TileDim-Ycomp)*1:(TileDim-Ycomp)*1+TileDim) = dummyTile;
        %     maskimg(1+2*Xcomp:TileDim+2*Xcomp,1+(TileDim-Ycomp)*2:(TileDim-Ycomp)*2+TileDim) = dummyTile;
        end
    end
end
end