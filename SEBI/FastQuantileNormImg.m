% FastQuantileNormImg.m
% 09/02/2011: Gerry wrote it
% This script will implement quantile normalization across a large set of
% images faster than IterativeQuantileNormImg. It cannot deal with any NaN
% values in images. 
%
% todo: uint8/16 imgs; input imgs of diff sizes
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

inputDir = 'F:\_SEBI\2011-08-04 56dai pMAX hippo 060311-09\8-bit LSM\Complete tiff series for normalization'; % path to your images
filetype = 'tif'; % type of image, e.g. tif

% get list of images
cd(inputDir);
ImgList = dir(['*.' filetype]);

fprintf(1,'\nReading image values...');
for a=1:length(ImgList)
    % load images
    TempImg = imread(ImgList(a).name);
    TempImgDims = size(TempImg);
    
    % vectorize
    TempImg = double(TempImg(:));

    % sort, but save how you sorted
    Indices = 1:length(TempImg);
    Indices = Indices';
    TempImgWIndx = [TempImg Indices];
    Sorted = sortrows(TempImgWIndx,1);
    save(ImgList(a).name(1:end-4),'Sorted','TempImgDims');

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

fprintf(1,'\nWriting normalize values...\n');
% put this value in all the images
for b=1:length(ImgList)
    % load image with indx
    xx = load(ImgList(b).name(1:end-4));
    xx.Sorted(:,1) = ImgMeans;
    
    % reverse sort via the indx column
    NewSorted = sortrows(xx.Sorted,2);
    
    % put these values in the actual image again
    Img = reshape(NewSorted(:,1),xx.TempImgDims);
    
    % then save the now normalized image
    imwrite(uint8(Img),[ImgList(b).name(1:end-4) '_normalized'],'tiff','Compression','none','Resolution',[96 96]);
    
    clear xx Img;
end
