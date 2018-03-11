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
% 2/15/2017: Gerry modified again to now exclusively use binary files,
% because we never really made full use of the nrrd spec anyway, and
% because of some odd bugs in the nrrdWriter and nrrdread code -- these all
% just write to binary files anyway
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

inputDir = 'H:\EXP48-52-53-91_CTRL49-55-56-73-74-86_ISO50-92-93-94_SCAT98_SING99-100-101-105_NOUV107\reformatted\c2c3RG_qnormd\qnormOfmeanvol'; % path to your images
fileidentifier = '*.nrrd'; % wildcard to search for files of interest
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
    fid = fopen(fullfile(inputDir,[ImgName '_qnormtempdata.raw']),'wb'); % open binary file for writing
    fwrite(fid,Sorted,'double'); % write values
    fclose(fid); % close file
    
    % also save the shape of this matrix
    SortedShape = size(Sorted);
    save(fullfile(inputDir,[ImgName '_qnormtempdata.mat']),'SortedShape');
    
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
fid = fopen(fullfile(inputDir,'ImgMeans.nrrd'),'wb'); % open binary file for writing
fwrite(fid,ImgMeans,'double'); % write values--save just in case!
fclose(fid); % close file
save('ImgDims','TempImgDims'); % also save image dimensions

fprintf(1,'\nWriting normalized values...\n');
% put this value in all the images
for b=1:length(ImgList)
    FullImgPath2 = fullfile(inputDir,ImgList(b).name);
    [~,ImgName2,~] = fileparts(FullImgPath2);
    
    % load image with indx
    fid = fopen(fullfile(inputDir,[ImgName2 '_qnormtempdata.raw']),'r'); % open binary file for reading
    PrevSorted = fread(fid,'double');
    fclose(fid);
    xx = load(fullfile(inputDir,[ImgName2 '_qnormtempdata.mat']));
    SortedShape = xx.SortedShape;
    PrevSorted = reshape(PrevSorted,SortedShape);
    PrevSorted(:,1) = ImgMeans;
    
    % reverse sort via the indx column
    NewSorted = sortrows(PrevSorted,2);
    
    % put these values in the actual image again
    Img = reshape(NewSorted(:,1),TempImgDims);
    
    % then save the now normalized image
    fid = fopen(fullfile(inputDir,[ImgName2 '_qnormd.raw']),'wb'); % open binary file for writing
    fwrite(fid,Img,'double'); % write values
    fclose(fid); % close file
end
