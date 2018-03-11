% FastQuantileNormImg3.m
% 09/02/2011: Gerry wrote it
% 1/5/2017: Gerry forked original version (not v2) this for v3. Bfmatlab 
% (bioformats for matlab) is used to export the image at the end. 
% Incorporated the 8 vs 16 bit choice from v2, but not the 0 removal steps. 
% Also cleaned up the code a bit to function more smoothly (e.g. using
% things like fullfile and not requiring change of working directory)
% This script will now also be able to handle quantile normalization across
% multiple image volumes
% 2/9/2017: Gerry modified once again to exclusively utilize nrrd for all
% I/O via nrrdread and nrrdWriter to speedup I/O (since single threaded
% matlab v7.3 compression and writing is super slow)
%
% This script will implement quantile normalization across a large set of
% images faster than IterativeQuantileNormImg. It cannot deal with any NaN
% values in images. 
%
% Dependencies: nrrdread, nrrdWriter
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

inputDir = 'H:\RG-exp-ctrl-iso-all-registered'; % path to your images
fileidentifier = '*RG.nrrd'; % wildcard to search for files of interest
yxzscale = [0.814 0.814 5]; % FYI: should be able to extract this from nrrd file

% get list of images
ImgList = dir(fullfile(inputDir,fileidentifier));

fprintf(1,'\nReading image values...');
for a=1:length(ImgList)
    FullImgPath = fullfile(inputDir,ImgList(a).name);
    [~,ImgName,~] = fileparts(FullImgPath);
    
    % load images
    TempImg = nrrdread(FullImgPath);
    TempImgDims = size(TempImg);
    
    % vectorize
    TempImg = double(TempImg(:));

    % sort, but save how you sorted
    Indices = 1:length(TempImg);
    Indices = Indices';
    TempImgWIndx = [TempImg Indices];
    Sorted = sortrows(TempImgWIndx,1);
    nrrdWriter(fullfile(inputDir,[ImgName '_qnormtempdata.nrrd']),Sorted,[1 1 1], [0 0 0], 'raw');

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
nrrdWriter(fullfile(inputDir,'ImgMeans.nrrd'),ImgMeans,[1 1 1],[0 0 0],'raw'); % save just in case!
save('ImgDims','TempImgDims'); % also save image dimensions

fprintf(1,'\nWriting normalized values...\n');
% put this value in all the images
for b=1:length(ImgList)
    FullImgPath2 = fullfile(inputDir,ImgList(b).name);
    [~,ImgName2,~] = fileparts(FullImgPath2);
    
    % load image with indx
    PrevSorted = nrrdread(fullfile(inputDir,[ImgName2 '_qnormtempdata.nrrd']));
    PrevSorted(:,1) = ImgMeans;
    
    % reverse sort via the indx column
    NewSorted = sortrows(PrevSorted,2);
    
    % put these values in the actual image again
    Img = reshape(NewSorted(:,1),TempImgDims);
    
    % then save the now normalized image
    nrrdWriter(fullfile(inputDir,[ImgName2 '_qnormd.nrrd']),Img,yxzscale, [0 0 0], 'raw');
end
