function bgnoise = ExtractBackgroundNoise(ImgName,FullImgPath)
% function bgnoise = ExtractBackgroundNoise(ImgName,FullImgPath)
% 8/6/2015: Gerry wrote it
% This function will take as input an image name and its full path and
% export the average intensity in a small square (end-50:end-25) over all
% frames. This function is most useful for extracting background noise
% signals from a given region in a given slice. A matlab file containing
% this bgnoise matrix will be exported in the same folder as the original
% image.
% NOTE: this function accepts only tiff stacks

% get img info
ImgInfo = imfinfo(fullfile(FullImgPath,ImgName));

if ImgInfo(1).FileSize < 2^32 % use regular tiffread if less than 4GB
    CurrImg = tiffread_gerry(fullfile(FullImgPath,ImgName));
else % else read raw IJ file
    temp = imfinfo(ImgName);
    tempidx = find(temp.ImageDescription=='=');
    framestring = temp.ImageDescription(tempidx(2)+1:tempidx(3)-7);
    j = str2double(framestring);
    CurrImg = ReadRawIJSlices(fullfile(FullImgPath,ImgName),ImgInfo,1,j);
end

% get a pre-specified region of background
bgnoise = CurrImg(end-50:end-25,end-50:end-25,:);
bgnoise = reshape(bgnoise,[size(bgnoise,1)*size(bgnoise,2) size(bgnoise,3)]);
bgnoise = mean(bgnoise,1);

save(fullfile(FullImgPath,[ImgName(1:end-4) '_bgnoise']),'bgnoise');
end

