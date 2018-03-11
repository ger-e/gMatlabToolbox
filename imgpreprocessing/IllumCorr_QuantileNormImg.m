% IllumCorr_QuantileNormImg.m
%
% 10/2010: Gerry wrote it based upon RMA_QuantileNormImg.m
%
% This script will perform a correction for nonuniform illumination of your
% images both within a plane (vignetting, e.g.) and across planes
% (decreased laser power in deeper portions, e.g.).  This will be achieved
% by an in-plane and cross-plane normalization, respectively.  The in-plane
% normalization requires an image of a uniform fluorescent slide, 'bright', for each
% channel you wish to normalize.  The across-plane normalization utilizes
% quantile normalization (normally used on affymetrix microarray data,
% e.g.)
%
% This script's solution to the issue that some images may have different
% xyz dimensions is to divide the images up into constituent tiles (and
% thus assumes that all the variation in image size is in quantal units of
% tiles). This does mean that you must have 0% overlap of tiles when
% acquiring
%
% Input images need to be numbered from 1 to n
% Input 'bright' images need to be numbered from BrightC1 to BrightCn and
% need to be acquired with the same TileDim, objective, and zoom as input
% images; only need a single plane image for this
%
% Note: this script requires Bioinformatics toolbox
% Note: your images must have the same number of channels, although the
% number of z-slices and xy dimensions can vary

clear all;
close all;

% things to modify---------------------------------------------------------
NumImgs = 1; % number of images you want to normalize over
TileDim = 1024; % dimension of each square tile for tiled images; just enter the dimension of the image if not tiling
TempImg = LSMto4DMatrix('1.lsm'); % load in the first image to get number of channels
MaskChannels = [0 1 0 0 0]; % size(MaskChannels) = NumChannels; mask channels you don't want to perform the preprocessing on (i.e. cytoplasmic stains); 0 means mask, 1 means don't mask
% -------------------------------------------------------------------------

% do preprocessing on a per channel basis
for d=1:size(TempImg,4)
    % load your images into an array
    ImgArray = [];
    ImgDims = zeros(NumImgs,3); % you'll need this info to reconstruct your images later
    NumTiles = zeros(NumImgs,1);% you'll need this info to reconstruct your images later
    fprintf(1,'\n');
    for a=1:NumImgs
        Img = LSMto4DMatrix([num2str(a) '.lsm']); % load in your image
        ImgDims(a,:) = [size(Img,1) size(Img,2) size(Img,3)];
        NumTiles(a) = size(Img,3)*(size(Img,1)/TileDim)*(size(Img,2)/TileDim);
        for g=1:size(Img,3)
            for f=1:size(Img,1)/TileDim
                for h=1:size(Img,2)/TileDim
                    CurrTile = Img(1+(f-1)*TileDim:f*TileDim,1+(h-1)*TileDim:h*TileDim,g,d); % take 1 tile from 1 slice from 1 channel; linearlize the tile
                    ImgArray = [ImgArray CurrTile(:)];
                end
            end
        end
        fprintf(1,'.');
    end
    
    % save some memory!
    clear TempImg;
    
    % let the user know where we are in the script!
    fprintf(1,'\nImages loaded for Channel %i!',d);

    if(MaskChannels(d))
        % save some memory!
        PreProcessedImg = ImgArray;
        clear ImgArray;

        % flat field illumination correction; currently just for cy2
        Bright = LSMto4DMatrix(['BrightC' num2str(d) '.lsm']);
        fprintf(1,'\nNow performing nonuniform illumination correction');
        for k=1:size(PreProcessedImg,2)
            PreProcessedImg(:,k) = PreProcessedImg(:,k)./Bright(:);
            PreProcessedImg(:,k) = PreProcessedImg(:,k)./max(PreProcessedImg(:,k))*255;
        end
        fprintf(1,'...done for Channel %i!',d);
        
        % now perform quantile normalization
        fprintf(1,'\nNow performing quantile normalization');
        figure(10);
        PreProcessedImg = quantilenorm(PreProcessedImg,'Display',1);
        fprintf(1,'...done for Channel %i!',d);

        fprintf(1,'\nImages processed (Channel %i), exporting now',d);
    else
        fprintf(1,'\nImages for Channel %i are masked!\nNo preprocessing will be performed!\nExporting now...',d);        
        PreProcessedImg = ImgArray;
        clear ImgArray;
    end
    % now get your images back and export
    TilesExported = 0;
    for b=1:NumImgs
        % reconstruct your images here
        Tiles = zeros(TileDim,TileDim,NumTiles(b));
        for i=1:NumTiles(b)
            Tiles(:,:,i) = reshape(PreProcessedImg(:,i+TilesExported),[TileDim TileDim]);
        end
        TilesExported = TilesExported + NumTiles(b); % keep track of the number of tiles exported for proper indexing on the next iteration
        Img = zeros(ImgDims(b,:));
        Count = 1;
        for j=1:size(Img,3)
            for k=1:size(Img,1)/TileDim
                for m=1:size(Img,2)/TileDim
                    Img(1+(k-1)*TileDim:k*TileDim,1+(m-1)*TileDim:m*TileDim,j) = Tiles(:,:,Count); % just do the same as earlier, but in reverse
                    Count = Count + 1;
                end
            end
        end
        
        % export the images here
        for c=1:size(Img,3)
            % output to image stack on a per channel basis
            imwrite(uint8(Img(:,:,c)),['PreProcessedImg' num2str(b) 'c_' num2str(d) '.tif'],'tiff','Compression','none','Resolution',[96 96],'WriteMode','append'); 
        end
        fprintf(1,'.');
    end
end