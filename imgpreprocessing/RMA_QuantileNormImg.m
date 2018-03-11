% RMA_QuantileNormImg.m
%
% 4/2010: Gerry wrote it
%
% This script will perform RMA background adjustment and quantile
% normalization (normally used on affymetrix microarray data) on confocal
% images
%
% This script's solution to the issue that some images may have different
% xyz dimensions is to divide the images up into constituent tiles (and
% thus assumes that all the variation in image size is in quantal units of
% tiles)
%
% Input images need to be numbered from 1 to n
%
% Note: this script requires Bioinformatics toolbox
% Note: your images must have the same number of channels, although the
% number of z-slices and xy dimensions can vary

clear all;
close all;

% things to modify---------------------------------------------------------
NumImgs = 1; % number of images you want to normalize over
TileDim = 512; % dimension of each square tile for tiled images; just enter the dimension of the image if not tiling
TempImg = LSMto4DMatrix('1.lsm'); % load in the first image to get number of channels
MaskChannels = [1 1 1 1 0]; % size(MaskChannels) = NumChannels; mask channels you don't want to perform the preprocessing on (i.e. cytoplasmic stains)
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
                
        fprintf(1,'\nNow performing quantile normalization');

        % now perform quantile normalization
        figure(10);
        PreProcessedImg = quantilenorm(PreProcessedImg,'Display',1);
        fprintf(1,'...done for Channel %i!',d);

        % let the user know where we are in the script!
        fprintf(1,'\nNow performing RMA background adjustment');

        % now perform a basic RMA background adjustment
        PreProcessedImg = rmabackadj(PreProcessedImg,'showplot',1);
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
            % NOTE: tiff will automatically default to 72dpi resolution!!!
            imwrite(uint8(Img(:,:,c)),['PreProcessedImg' num2str(b) '_c' num2str(d) '_z' num2str(c) '.tif'],'tiff','Compression','none'); 
%             save(['PreProcessedImg' num2str(b) '_c' num2str(d) '_z'
%             num2str(c)],'PreProcessedImg'); % don't bother saving...takes
%             too long
        end
        fprintf(1,'.');
    end
end

% old code--ignore
%     % perform a basic RMA background adjustment
%     RMAImg = rmabackadj(ImgArray);
% 
%     for e=1:NumImgs
%     Img = reshape(RMAImg(:,e),size(TempImg));
%         for c=1:size(Img,3)
%             figure(1); imshow(Img(:,:,c));
%             print('-f1', '-dtiffnocompression',['RMAImg' num2str(e) '_c' num2str(d) '_z' num2str(c)]);
%             save(['RMAImg' num2str(e) '_c' num2str(d) '_z' num2str(c)],'RMAImg');
%         end
%     end