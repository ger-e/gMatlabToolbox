% FastQuantileNormImg3.m
% 09/02/2011: Gerry wrote it
% 1/5/2017: Gerry forked original version (not v2) this for v3. Bfmatlab 
% (bioformats for matlab) is used to export the image at the end. 
% Incorporated the 8 vs 16 bit choice from v2, but not the 0 removal steps. 
% Also cleaned up the code a bit to function more smoothly (e.g. using
% things like fullfile and not requiring change of working directory)
% This script will now also be able to handle quantile normalization across
% multiple image volumes
%
% This script will implement quantile normalization across a large set of
% images faster than IterativeQuantileNormImg. It cannot deal with any NaN
% values in images. 
%
% Dependencies: bfmatlab, tiffread_gerry
%
% Algorithm
% 1-load an image
% 2-vectorize it
% 3-sort it, save how you sorted it (for unsorting)
% 4-add its sorted values to the summing vector
% 5-repeate for all images
% 6-take the mean of the summing vector
% 7-put this value in all the images
%
% scales with 2*numImgs (as opposed to numImgs^2 with
% IterativeQuantileNorm)

inputDir = 'H:\campari-registration\reformatted\quantilenormalized-excludesmfish'; % path to your images
filetype = 'tif'; % type of image, e.g. tif
bitLevel = 16; % bit level of image: 8 or 16

% check bitLevel validity
if bitLevel ~= 8 && bitLevel ~= 16
    fprintf(1,'\nWARNING! Incorrect bitlevel: %d',bitLevel);
end

% get list of images
ImgList = dir(fullfile(inputDir,['*.' filetype]));

fprintf(1,'\nReading image values...');
for a=1:length(ImgList)
    % load images
    TempImg = tiffread_gerry(fullfile(inputDir,ImgList(a).name));
    TempImgDims = size(TempImg);
    
    % vectorize
    TempImg = double(TempImg(:));

    % sort, but save how you sorted
    Indices = 1:length(TempImg);
    Indices = Indices';
    TempImgWIndx = [TempImg Indices];
    Sorted = sortrows(TempImgWIndx,1);
    save(fullfile(inputDir,ImgList(a).name(1:end-4)),'Sorted','TempImgDims','-v7.3');

    % add sorted values to a total sum vector
    if a==1
        SummingVector = Sorted(:,1);
    else
        SummingVector = SummingVector + Sorted(:,1);
    end

    clear Sorted TempImg;
end

% get the mean
ImgMeans = SummingVector./length(ImgList);
save(fullfile(inputDir,'ImgMeans'),'ImgMeans'); % save just in case!

fprintf(1,'\nWriting normalized values...\n');
% put this value in all the images
for b=1:length(ImgList)
    % load image with indx
    xx = load(fullfile(inputDir,ImgList(b).name(1:end-4)));
    xx.Sorted(:,1) = ImgMeans;
    
    % reverse sort via the indx column
    NewSorted = sortrows(xx.Sorted,2);
    
    % put these values in the actual image again
    Img = reshape(NewSorted(:,1),xx.TempImgDims);
    
    % then save the now normalized image
    % then save the now normalized image
    if bitLevel == 8
        bfsave(uint8(Img),fullfile(inputDir,[ImgList(b).name(1:end-4) '_normalized.tif']));
    elseif bitLevel == 16
        bfsave(uint16(Img),fullfile(inputDir,[ImgList(b).name(1:end-4) '_normalized.tif']));
    else
        fprintf(1,'\nInvalid bitlevel: %d',bitLevel);
    end
        
    clear xx Img;
end
