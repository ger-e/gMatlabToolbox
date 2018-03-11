% FastQuantileNormImg.m
% 09/02/2011: Gerry wrote it
% 09/16/2011: Added ability to process images of different sizes
% 09/19/2011: Increased speed by removing additional image reloading step
% upon normalized image export.
%
% This script will implement quantile normalization across a large set of
% images faster than IterativeQuantileNormImg. It cannot deal with any NaN
% values in images. It can only deal with either 8 or 16-bit images
%
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

% settings to ...set
inputDir = 'K:\14-PaperReview_Revision\2012_JuanSong3\PV+CHAT\to use\3\PV'; % path to your images
filetype = 'tif'; % type of image, e.g. tif
bitLevel = 8; % bit level of image: 8 or 16

% check bitLevel validity
if bitLevel ~= 8 && bitLevel ~= 16
    fprintf(1,'\nWARNING! Incorrect bitlevel: %d',bitLevel);
end

% get list of images
cd(inputDir);
ImgList = dir(['*.' filetype]);

% get max img length and dimensions
TempImg = imread(ImgList(1).name);
MaxLength = length(TempImg(:));
TempImgDims = size(TempImg);

fprintf(1,'\nReading image values...');
for a=1:length(ImgList)
    % load images
    TempImg = imread(ImgList(a).name);

    
    % get img mask and segment
    mask = im2bw(TempImg,1/2^bitLevel); % mask out 0 values
    TempImgSeg = TempImg(mask); % segmented image
    
    % add in dummy values up to MaxLength
    Difference = MaxLength-length(TempImgSeg);
    AddValsIndx = ceil(rand(abs(Difference),1).*length(TempImgSeg)); % pick values from TempImgSeg randomly
    AddVals = TempImgSeg(AddValsIndx); % get the values
    TempImgSeg = [TempImgSeg(:)' AddVals(:)']'; % stick them on
        
    % vectorize
    TempImgSeg = double(TempImgSeg(:));
    
    % sort, but save how you sorted
    Indices = 1:length(TempImgSeg);
    Indices = Indices';
    TempImgWIndx = [TempImgSeg Indices];
    Sorted = sortrows(TempImgWIndx,1);
    save(ImgList(a).name(1:end-4),'Sorted','Difference','mask','MaxLength');

    % add sorted values to a total sum vector
    if a==1
        SummingVector = Sorted(:,1);
    else
        SummingVector = SummingVector + Sorted(:,1);
    end

    clear Sorted TempImg TempImgSeg mask;
end
fprintf(1,'Done!\n');

% get the mean
ImgMeans = SummingVector./length(ImgList);
save ImgMeans ImgMeans; % save just in case!

fprintf(1,'\nWriting normalized values...\n');
% put this value in all the images
for b=1:length(ImgList)
    % load image with indx, plus make a shell to put image into
    xx = load(ImgList(b).name(1:end-4));
    xx.Sorted(:,1) = ImgMeans;
    TempImg = zeros(TempImgDims);
    
    % reverse sort via the indx column
    NewSorted = sortrows(xx.Sorted,2);
    
    % remove dummy values
    NoDummy = NewSorted(1:(xx.MaxLength-xx.Difference),1);
    
    % put these values in the actual image again
    TempImg(xx.mask) = NoDummy;
    
    % then save the now normalized image
    if bitLevel == 8
        imwrite(uint8(TempImg),[ImgList(b).name(1:end-4) '_normalized.tiff'],'tiff','Compression','none','Resolution',[96 96]);
    elseif bitLevel == 16
        imwrite(uint16(TempImg),[ImgList(b).name(1:end-4) '_normalized.tiff'],'tiff','Compression','none','Resolution',[96 96]);
    else
        fprintf(1,'\nInvalid bitlevel: %d',bitLevel);
    end
    clear xx TempImg;
end
fprintf(1,'Done!\n');