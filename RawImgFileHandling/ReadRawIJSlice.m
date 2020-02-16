function Slice = ReadRawIJSlice(FullImgPath,Index)
% function Slice = ReadRawIJSlice(FullImgPath,Index)
% 12/23/2014: Gerry wrote it
% 1/9/2014: Gerry fixed bug: apparently I mixed up order of width and
% height...well honestly, I just guessed it the first time and guessed
% wrong
% This function will read in a raw ImageJ-created tif stack (>4GB files)

ImgInfo = imfinfo(FullImgPath);
fid = fopen(FullImgPath,'r','b');
fseek(fid,ImgInfo(1).StripOffsets,'bof'); % seek past header

% go to desired slice
if Index > 1
    fseek(fid,ImgInfo(1).StripOffsets+(Index-1).*2.*prod([ImgInfo.Width ImgInfo.Height]),'bof');
end

% read the slice and reshape
Slice = fread(fid,prod([ImgInfo.Height ImgInfo.Width]),[num2str(prod([ImgInfo.Width ImgInfo.Height]))  '*uint16']);
Slice = reshape(Slice,[ImgInfo.Width ImgInfo.Height]);
Slice = Slice';
fclose(fid);
end