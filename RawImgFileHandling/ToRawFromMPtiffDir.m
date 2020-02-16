function ToRawFromMPtiffDir(inDirectory,outDirectory)
% function ToRawFromMPtiffDir(inDirectory,outDirectory)
% 5/25/2017: Gerry wrote it
% Converts sequential multi-page tiff files (e.g. exported from
% HCImageLive) into a single raw data file. A *.mat file will also be
% exported with simple image dimensions metadata

Imgs = dir(fullfile(inDirectory,'*.tif')); % get img names
[~,ImgName,~] = fileparts(Imgs(1).name);
fileID = fopen(fullfile(outDirectory,[ImgName '.raw']),'a+'); % open file for writing with appending
TotImgSlices = 0;
for a=1:length(Imgs)
    [CurrImg,bits] = tiffread_gerry(fullfile(inDirectory,Imgs(a).name));
    CurrImg = permute(CurrImg,[2 1 3]);
    TotImgSlices = TotImgSlices + size(CurrImg,3);
    fwrite(fileID,CurrImg(:),['uint' num2str(bits)],'ieee-le');
end
fclose(fileID);
ImgDims = [size(CurrImg,1) size(CurrImg,2) TotImgSlices];
save(fullfile(outDirectory,[ImgName '.mat']),'ImgDims');
end