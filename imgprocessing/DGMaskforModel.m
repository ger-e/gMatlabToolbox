% DGMaskforModel
% 08/06/2010: Gerry wrote it
% 09/20/2010: Downsampling factor now exported into image name
% 03/09/2011: Included optimizations for file input/reading
%
% This script will call GetImgMask to get a mask for each slice of input
% image, which you can then import directly into Imaris and generate a
% high-quality surface rendering of the mask.  The mask is generated by
% peeking at the DAPI channel or equivalent nuclear counterstain in the B
% channel of an RGB input bitmap image
% 
% This script requires GetImgMask in order to run.

% put this script in a separate directory from your images
% addpath(pwd);

% type of image you're loading in: lsm, tif, bmp, e.g.
ImgType = 'tif';

% absolute path to directory of the images
% ImgDir = 'D:\Gerry\Nes-Zeg 1x TMX B9 RH 2d _in publication\Prelim Masks (Photoshop)\originals\1Piece';
ImgDir = 'E:\Joey\Ryan Data\358LH_for new simulation';
% down sampling factor (from 0 to 1)
DownSample = 1;

% get list of image names
cd(ImgDir);
imgList = dir(['*.' ImgType]);
counter = 1; % set counter = 0 for fully automated; = 1 for hand-holding
debug = 1; % set to same value as counter

for a=1:size(imgList,1)
    % load the images of the stack one by one
    CurrentImg = imread(imgList(a,1).name);
    
    % output a corresponding downsampled image
    imwrite(imresize(CurrentImg,DownSample),[imgList(a,1).name(1:end-4) '_downSampled_' num2str(DownSample) '.bmp'],'bmp');
    
%     CurrentImg = CurrentImg(:,:,3); % take only the B channel with DAPI in it
    
    % find the mask for the image
    answer = 0;
    while ~answer
        [CurrentImg2 answer counter] = GetImgMask(CurrentImg,counter,debug);
    end
    CurrentImg = CurrentImg2; % to prevent overwriting of img when in hand-holding mode
    CurrentImg = imresize(CurrentImg,DownSample); % then down sample
    
%     CurrentImg = im2bw(CurrentImg,0); % use this only if you're doing
%     more than 1 ROI to get a proper bw image
    
    % now export the mask
    imwrite(CurrentImg,[imgList(a,1).name(1:end-4) '_mask.bmp'],'bmp');
end